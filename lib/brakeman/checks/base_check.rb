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

  class << self
    attr_accessor :name

    def inherited(subclass)
      subclass.name = subclass.to_s.match(/^Brakeman::(.*)$/)[1]
    end
  end

  #Initialize Check with Checks.
  def initialize(app_tree, tracker)
    super()
    @app_tree = app_tree
    @results = [] #only to check for duplicates
    @warnings = []
    @tracker = tracker
    @string_interp = false
    @current_set = nil
    @current_template = @current_module = @current_class = @current_method = nil
    @active_record_models = nil
    @mass_assign_disabled = nil
    @has_user_input = nil
    @safe_input_attributes = Set[:to_i, :to_f, :arel_table, :id]
    @comparison_ops  = Set[:==, :!=, :>, :<, :>=, :<=]
  end

  #Add result to result list, which is used to check for duplicates
  def add_result result, location = nil
    location ||= (@current_template && @current_template.name) || @current_class || @current_module || @current_set || result[:location][:class] || result[:location][:template]
    location = location[:name] if location.is_a? Hash
    location = location.name if location.is_a? Brakeman::Collection
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
    unless @comparison_ops.include? exp.method
      process exp.target if sexp? exp.target
      process_call_args exp
    end

    target = exp.target

    unless always_safe_method? exp.method
      if params? target
        @has_user_input = Match.new(:params, exp)
      elsif cookies? target
        @has_user_input = Match.new(:cookies, exp)
      elsif request_env? target
        @has_user_input = Match.new(:request, exp)
      elsif sexp? target and model_name? target[1] #TODO: Can this be target.target?
        @has_user_input = Match.new(:model, exp)
      end
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

  #Does not actually process string interpolation, but notes that it occurred.
  def process_dstr exp
    @string_interp = Match.new(:interp, exp)
    process_default exp
  end

  private

  def always_safe_method? meth
    @safe_input_attributes.include? meth or
      @comparison_ops.include? meth
  end

  def boolean_method? method
    method[-1] == "?"
  end

  #Report a warning
  def warn options
    extra_opts = { :check => self.class.to_s }

    warning = Brakeman::Warning.new(options.merge(extra_opts))
    warning.file = file_for warning
    warning.relative_path = relative_path(warning.file)

    @warnings << warning
  end

  #Run _exp_ through OutputProcessor to get a nice String.
  def format_output exp
    Brakeman::OutputProcessor.new.format(exp).gsub(/\r|\n/, "")
  end

  #Checks if mass assignment is disabled globally in an initializer.
  def mass_assign_disabled?
    return @mass_assign_disabled unless @mass_assign_disabled.nil?

    @mass_assign_disabled = false

    if version_between?("3.1.0", "3.9.9") and
      tracker.config.whitelist_attributes?

      @mass_assign_disabled = true
    elsif tracker.options[:rails4] && (!tracker.config.has_gem?(:protected_attributes) || tracker.config.whitelist_attributes?)

      @mass_assign_disabled = true
    else
      #Check for ActiveRecord::Base.send(:attr_accessible, nil)
      tracker.check_initializers(:"ActiveRecord::Base", :attr_accessible).each do |result|
        call = result.call
        if call? call
          if call.first_arg == Sexp.new(:nil)
            @mass_assign_disabled = true
            break
          end
        end
      end

      unless @mass_assign_disabled
        tracker.check_initializers(:"ActiveRecord::Base", :send).each do |result|
          call = result.call
          if call? call
            if call.first_arg == Sexp.new(:lit, :attr_accessible) and call.second_arg == Sexp.new(:nil)
              @mass_assign_disabled = true
              break
            end
          end
        end
      end

      unless @mass_assign_disabled
        #Check for
        #  class ActiveRecord::Base
        #    attr_accessible nil
        #  end
        matches = tracker.check_initializers([], :attr_accessible)

        matches.each do |result|
          if result.module == "ActiveRecord" and result.result_class == :Base
            arg = result.call.first_arg

            if arg.nil? or node_type? arg, :nil
              @mass_assign_disabled = true
              break
            end
          end
        end
      end
    end

    #There is a chance someone is using Rails 3.x and the `strong_parameters`
    #gem and still using hack above, so this is a separate check for
    #including ActiveModel::ForbiddenAttributesProtection in
    #ActiveRecord::Base in an initializer.
    if not @mass_assign_disabled and version_between?("3.1.0", "3.9.9") and tracker.config.has_gem? :strong_parameters
      matches = tracker.check_initializers([], :include)
      forbidden_protection = Sexp.new(:colon2, Sexp.new(:const, :ActiveModel), :ForbiddenAttributesProtection)

      matches.each do |result|
        if call? result.call and result.call.first_arg == forbidden_protection
          @mass_assign_disabled = true
        end
      end

      unless @mass_assign_disabled
        matches = tracker.check_initializers(:"ActiveRecord::Base", [:send, :include])

        matches.each do |result|
          call = result.call
          if call? call and (call.first_arg == forbidden_protection or call.second_arg == forbidden_protection)
            @mass_assign_disabled = true
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

    location ||= (@current_template && @current_template.name) || @current_class || @current_module || @current_set || result[:location][:class] || result[:location][:template]

    location = location[:name] if location.is_a? Hash
    location = location.name if location.is_a? Brakeman::Collection
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
    elsif call? exp and not always_safe_method? exp.method
      if params? exp
        return Match.new(:params, exp)
      elsif cookies? exp
        return Match.new(:cookies, exp)
      elsif request_env? exp
        return Match.new(:request, exp)
      else
        has_immediate_user_input? exp.target
      end
    elsif sexp? exp
      case exp.node_type
      when :dstr
        exp.each do |e|
          if sexp? e
            match = has_immediate_user_input?(e)
            return match if match
          end
        end
        false
      when :evstr
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

      if always_safe_method? method
        false
      elsif call? target and not method.to_s[-1,1] == "?"
        if has_immediate_model?(target, out)
          exp
        else
          false
        end
      elsif model_name? target
        exp
      else
        false
      end
    elsif sexp? exp
      case exp.node_type
      when :dstr
        exp.each do |e|
          if sexp? e and match = has_immediate_model?(e, out)
            return match
          end
        end
        false
      when :evstr
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
    elsif call? exp and exp.target.nil? and exp.method == :current_user
      true
    elsif sexp? exp
      @models.include? class_name(exp)
    else
      false
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
  def version_between? low_version, high_version, current_version = nil
    current_version ||= rails_version
    return false unless current_version

    version = current_version.split(".").map! { |n| n.to_i }
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

  def lts_version? version
    tracker.config.has_gem? :'railslts-version' and
    version_between? version, "2.3.18.99", tracker.config.gem_version(:'railslts-version')
  end

  def gemfile_or_environment gem_name = :rails
    if gem_name and info = tracker.config.get_gem(gem_name)
      info
    elsif @app_tree.exists?("Gemfile")
      "Gemfile"
    elsif @app_tree.exists?("gems.rb")
      "gems.rb"
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
      if model.ancestor? :"ActiveRecord::Base"
        @active_record_models[name] = model
      end
    end

    @active_record_models
  end

  def friendly_type_of input_type
    if input_type.is_a? Match
      input_type = input_type.type
    end

    case input_type
    when :params
      "parameter value"
    when :cookies
      "cookie value"
    when :request
      "request value"
    when :model
      "model attribute"
    else
      "user input"
    end
  end
end
