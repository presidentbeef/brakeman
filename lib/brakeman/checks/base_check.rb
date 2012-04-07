require 'sexp_processor'
require 'brakeman/processors/output_processor'
require 'brakeman/processors/lib/processor_helper'
require 'brakeman/warning'
require 'brakeman/util'

#Basis of vulnerability checks.
class Brakeman::BaseCheck < SexpProcessor
  include Brakeman::ProcessorHelper
  include Brakeman::Util
  attr_reader :tracker, :warnings

  CONFIDENCE = { :high => 0, :med => 1, :low => 2 }

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
    self.strict = false
    self.auto_shift_type = false
    self.require_empty = false
    self.default_method = :process_default
    self.warn_on_default = false
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
    process exp[1] if sexp? exp[1]
    process exp[3]

    if params? exp[1]
      @has_user_input = :params
    elsif cookies? exp[1]
      @has_user_input = :cookies
    elsif request_env? exp[1]
      @has_user_input = :request
    elsif sexp? exp[1] and model_name? exp[1][1]
      @has_user_input = :model
    end

    exp
  end

  #Note that params are included in current expression
  def process_params exp
    @has_user_input = :params
    exp
  end

  #Note that cookies are included in current expression
  def process_cookies exp
    @has_user_input = :cookies
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
  def parent? model, parent
    if model == nil
      false
    elsif model[:parent] == parent
      true
    elsif model[:parent]
      parent? tracker.models[model[:parent]], parent
    else
      false
    end
  end

  #Checks if mass assignment is disabled globally in an initializer.
  def mass_assign_disabled?
    return @mass_assign_disabled unless @mass_assign_disabled.nil?
        
    @mass_assign_disabled = false

    if version_between?("3.1.0", "4.0.0") and 
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
    @string_interp = true
    exp
  end

  #Checks if an expression contains string interpolation.
  def include_interp? exp
    @string_interp = false
    process exp
    @string_interp
  end

  #Checks if _exp_ includes parameters or cookies, but this only works 
  #with the base process_default.
  def include_user_input? exp
    @has_user_input = false
    process exp
    @has_user_input
  end

  #This is used to check for user input being used directly.
  #
  #Returns false if none is found, otherwise it returns an array
  #where the first element is the type of user input 
  #(either :params or :cookies) and the second element is the matching 
  #expression
  def has_immediate_user_input? exp
    if exp.nil?
      false
    elsif params? exp
      return :params, exp
    elsif cookies? exp
      return :cookies, exp
    elsif call? exp
      if params? exp[1]
        return :params, exp
      elsif cookies? exp[1]
        return :cookies, exp
      elsif request_env? exp[1]
        return :request, exp
      else
        false
      end
    elsif sexp? exp
      case exp.node_type
      when :string_interp
        exp.each do |e|
          if sexp? e
            type, match = has_immediate_user_input?(e)
            if type
              return type, match
            end
          end
        end
        false
      when :string_eval
        if sexp? exp[1]
          if exp[1].node_type == :rlist
            exp[1].each do |e|
              if sexp? e
                type, match = has_immediate_user_input?(e)
                if type
                  return type, match
                end
              end
            end
            false
          else
            has_immediate_user_input? exp[1]
          end
        end
      when :format
        has_immediate_user_input? exp[1]
      when :if
        (sexp? exp[2] and has_immediate_user_input? exp[2]) or 
        (sexp? exp[3] and has_immediate_user_input? exp[3])
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
      exp = exp[1]
    end

    if call? exp
      target = exp[1]
      method = exp[2]

      if call? target and not method.to_s[-1,1] == "?"
        has_immediate_model? target, out
      elsif model_name? target 
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
        if sexp? exp[1]
          if exp[1].node_type == :rlist
            exp[1].each do |e|
              if sexp? e and match = has_immediate_model?(e, out)
                return match
              end
            end
            false
          else
            has_immediate_model? exp[1], out
          end
        end
      when :format
        has_immediate_model? exp[1], out
      when :if
        ((sexp? exp[2] and has_immediate_model? exp[2], out) or 
         (sexp? exp[3] and has_immediate_model? exp[3], out))
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
      find_chain exp[1], target
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
      if v < low_version[i]
        return false
      elsif v > low_version[i]
        break
      end
    end

    version.each_with_index do |v, i|
      if v > high_version[i]
        return false
      elsif v < high_version[i]
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
end
