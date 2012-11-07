require 'brakeman/processors/output_processor'
require 'brakeman/processors/lib/processor_helper'
require 'brakeman/warning'
require 'brakeman/util'

#Basis of vulnerability checks.
class Brakeman::BaseCheck < Brakeman::SexpProcessor
  include Brakeman::ProcessorHelper
  include Brakeman::Util
  attr_reader :tracker, :warnings

  CONFIDENCE = { :high => 0, :med => 1, :low => 2 }

  Match = Struct.new(:type, :match)

  #Initialize Check with Checks.
  def initialize tracker
    super()
    @results = [] #only to check for duplicates
    @warnings = []
    @tracker = tracker
    @string_interp = false
    @current_set = nil
    @current_template = @current_module = @current_class = @current_method = nil
    @mass_assign_disabled = nil
  end

  #Add result to result list, which is used to check for duplicates
  def add_result result, location = nil
    location ||= (@current_template && @current_template[:name]) || @current_class || @current_module || @current_set || result[:location][1]
    location = location[:name] if location.is_a? Hash
    location = location.to_sym

    if result.is_a? Hash
      line = result[:call].original_line || result[:call].line
    elsif sexp? result
      line = result.original_line || result.line
    else
      raise ArgumentError
    end

    @results << [line, location, result]
  end

  #Default Sexp processing. Iterates over each value in the Sexp
  #and processes them if they are also Sexps.
  def process_default exp
    exp.each_with_index do |e, i|
      if sexp? e
        process e
      else
        e
      end
    end

    exp
  end

  #Process calls and check if they include user input
  def process_call exp
    process exp.target if sexp? exp.target
    process_all exp.args

    target = exp.target

    if params? target
      @has_user_input = Match.new(:params, exp)
    elsif cookies? target
      @has_user_input = Match.new(:cookies, exp)
    elsif request_env? target
      @has_user_input = Match.new(:request, exp)
    elsif sexp? target and model_name? target[1]
      @has_user_input = Match.new(:model, exp)
    end

    exp
  end

  def process_if exp
    #This is to ignore user input in condition
    current_user_input = @has_user_input
    process exp.condition
    @has_user_input = current_user_input

    process exp.then_clause if sexp? exp.then_clause
    process exp.else_clause if sexp? exp.else_clause

    exp
  end

  #Note that params are included in current expression
  def process_params exp
    @has_user_input = Match.new(:params, exp)
    exp
  end

  #Note that cookies are included in current expression
  def process_cookies exp
    @has_user_input = Match.new(:cookies, exp)
    exp
  end

  private

  #Report a warning 
  def warn options
    warning = Brakeman::Warning.new(options.merge({ :check => self.class.to_s }))
    warning.file = file_for warning

    @warnings << warning 
  end 

  #Run _exp_ through OutputProcessor to get a nice String.
  def format_output exp
    Brakeman::OutputProcessor.new.format(exp).gsub(/\r|\n/, "")
  end

  #Checks if the model inherits from parent,
  def ancestor? model, parent
    if model == nil
      false
    elsif model[:parent] == parent
      true
    elsif model[:parent]
      ancestor? tracker.models[model[:parent]], parent
    else
      false
    end
  end

  def unprotected_model? model
    model[:attr_accessible].nil? and !parent_classes_protected?(model) and ancestor?(model, :"ActiveRecord::Base")
  end

  # go up the chain of parent classes to see if any have attr_accessible
  def parent_classes_protected? model
    if model[:attr_accessible]
      true
    elsif parent = tracker.models[model[:parent]]
      parent_classes_protected? parent
    else
      false
    end
  end

  #Checks if mass assignment is disabled globally in an initializer.
  def mass_assign_disabled?
    return @mass_assign_disabled unless @mass_assign_disabled.nil?
        
    @mass_assign_disabled = false

    if version_between?("3.1.0", "4.0.0") and 
      tracker.config[:rails] and
      tracker.config[:rails][:active_record] and 
      tracker.config[:rails][:active_record][:whitelist_attributes] == Sexp.new(:true)

      @mass_assign_disabled = true
    else
      matches = tracker.check_initializers(:"ActiveRecord::Base", :send)

      if matches.empty?
        matches = tracker.check_initializers([], :attr_accessible)

        matches.each do |result|
          if result[1] == :ActiveRecord and result[2] == :Base
            arg = result[-1][3][1]

            if arg.nil? or node_type? arg, :nil
              @mass_assign_disabled = true
              break
            end
          end
        end
      else
        matches.each do |result|
          if result[-1][3] == Sexp.new(:arglist, Sexp.new(:lit, :attr_accessible), Sexp.new(:nil))
            @mass_assign_disabled = true
            break
          end
        end
      end
    end

    @mass_assign_disabled
  end

  #This is to avoid reporting duplicates. Checks if the result has been
  #reported already from the same line number.
  def duplicate? result, location = nil
    if result.is_a? Hash
      line = result[:call].original_line || result[:call].line
    elsif sexp? result
      line = result.original_line || result.line
    else
      raise ArgumentError
    end

    location ||= (@current_template && @current_template[:name]) || @current_class || @current_module || @current_set || result[:location][1]

    location = location[:name] if location.is_a? Hash
    location = location.to_sym

    @results.each do |r|
      if r[0] == line and r[1] == location
        if tracker.options[:combine_locations]
          return true
        elsif r[2] == result
          return true
        end
      end
    end

    false
  end

  #Ignores ignores
  def process_ignore exp
    exp
  end

  #Does not actually process string interpolation, but notes that it occurred.
  def process_string_interp exp
    @string_interp = Match.new(:interp, exp)
    exp
  end

  #Checks if an expression contains string interpolation.
  #
  #Returns Match with :interp type if found.
  def include_interp? exp
    @string_interp = false
    process exp
    @string_interp
  end

  #Checks if _exp_ includes user input in the form of cookies, parameters,
  #request environment, or model attributes.
  #
  #If found, returns a struct containing a type (:cookies, :params, :request, :model) and
  #the matching expression (Match#type and Match#match).
  #
  #Returns false otherwise.
  def include_user_input? exp
    @has_user_input = false
    process exp
    @has_user_input
  end

  #This is used to check for user input being used directly.
  #
  ##If found, returns a struct containing a type (:cookies, :params, :request) and
  #the matching expression (Match#type and Match#match).
  #
  #Returns false otherwise.
  def has_immediate_user_input? exp
    if exp.nil?
      false
    elsif params? exp
      return Match.new(:params, exp)
    elsif cookies? exp
      return Match.new(:cookies, exp)
    elsif call? exp
      if params? exp.target
        return Match.new(:params, exp)
      elsif cookies? exp.target
        return Match.new(:cookies, exp)
      elsif request_env? exp.target
        return Match.new(:request, exp)
      else
        false
      end
    elsif sexp? exp
      case exp.node_type
      when :string_interp
        exp.each do |e|
          if sexp? e
            match = has_immediate_user_input?(e)
            return match if match
          end
        end
        false
      when :string_eval
        if sexp? exp.value
          if exp.value.node_type == :rlist
            exp.value.each_sexp do |e|
              match = has_immediate_user_input?(e)
              return match if match
            end
            false
          else
            has_immediate_user_input? exp.value
          end
        end
      when :format
        has_immediate_user_input? exp.value
      when :if
        (sexp? exp.then_clause and has_immediate_user_input? exp.then_clause) or
        (sexp? exp.else_clause and has_immediate_user_input? exp.else_clause)
      when :or
        has_immediate_user_input? exp.lhs or
        has_immediate_user_input? exp.rhs
      else
        false
      end
    end
  end

  #Checks for a model attribute at the top level of the
  #expression.
  def has_immediate_model? exp, out = nil
    out = exp if out.nil?

    if sexp? exp and exp.node_type == :output
      exp = exp.value
    end

    if call? exp
      target = exp.target
      method = exp.method

      if call? target and not method.to_s[-1,1] == "?"
        has_immediate_model? target, out
      elsif model_name? target and method != :arel_table
        exp
      else
        false
      end
    elsif sexp? exp
      case exp.node_type
      when :string_interp
        exp.each do |e|
          if sexp? e and match = has_immediate_model?(e, out)
            return match
          end
        end
        false
      when :string_eval
        if sexp? exp.value
          if exp.value.node_type == :rlist
            exp.value.each_sexp do |e|
              if match = has_immediate_model?(e, out)
                return match
              end
            end
            false
          else
            has_immediate_model? exp.value, out
          end
        end
      when :format
        has_immediate_model? exp.value, out
      when :if
        ((sexp? exp.then_clause and has_immediate_model? exp.then_clause, out) or
         (sexp? exp.else_clause and has_immediate_model? exp.else_clause, out))
      when :or
        has_immediate_model? exp.lhs or
        has_immediate_model? exp.rhs
      else
        false
      end
    end
  end

  #Checks if +exp+ is a model name.
  #
  #Prior to using this method, either @tracker must be set to 
  #the current tracker, or else @models should contain an array of the model
  #names, which is available via tracker.models.keys
  def model_name? exp
    @models ||= @tracker.models.keys

    if exp.is_a? Symbol
      @models.include? exp
    elsif sexp? exp
      klass = nil
      begin
        klass = class_name exp
      rescue StandardError
      end

      klass and @models.include? klass
    else
      false
    end
  end

  #Finds entire method call chain where +target+ is a target in the chain
  def find_chain exp, target
    return unless sexp? exp 

    case exp.node_type
    when :output, :format
      find_chain exp.value, target
    when :call
      if exp == target or include_target? exp, target
        return exp 
      end
    else
      exp.each do |e|
        if sexp? e
          res = find_chain e, target
          return res if res
        end
      end
      nil
    end
  end

  #Returns true if +target+ is in +exp+
  def include_target? exp, target
    return false unless call? exp

    exp.each do |e|
      return true if e == target or include_target? e, target
    end

    false
  end

  #Returns true if low_version <= RAILS_VERSION <= high_version
  #
  #If the Rails version is unknown, returns false.
  def version_between? low_version, high_version
    return false unless tracker.config[:rails_version]

    version = tracker.config[:rails_version].split(".").map! { |n| n.to_i }
    low_version = low_version.split(".").map! { |n| n.to_i }
    high_version = high_version.split(".").map! { |n| n.to_i }

    version.each_with_index do |v, i|
      if v < low_version.fetch(i, 0)
        return false
      elsif v > low_version.fetch(i, 0)
        break
      end
    end

    version.each_with_index do |v, i|
      if v > high_version.fetch(i, 0)
        return false
      elsif v < high_version.fetch(i, 0)
        break
      end
    end

    true
  end

  def gemfile_or_environment
    if File.exist? File.expand_path "#{tracker.options[:app_path]}/Gemfile"
      "Gemfile"
    else
      "config/environment.rb"
    end
  end

  def self.description
    @description
  end

  def active_record_models
    return @active_record_models if @active_record_models

    @active_record_models = {}

    tracker.models.each do |name, model|
      if ancestor? model, :"ActiveRecord::Base"
        @active_record_models[name] = model
      end
    end

    @active_record_models
  end
end
