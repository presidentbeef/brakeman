
require 'brakeman/processors/lib/basic_processor'

#Processes configuration. Results are put in tracker.config.
#
#Configuration of Rails via Rails::Initializer are stored in tracker.config.rails.
#For example:
#
#  MyApp::Application.configure do
#    config.active_record.whitelist_attributes = true
#  end
#
#will be stored in
#
#  tracker.config.rails[:active_record][:whitelist_attributes]
#
#Values for tracker.config.rails will still be Sexps.
class Brakeman::Rails3ConfigProcessor < Brakeman::BasicProcessor
  RAILS_CONFIG = Sexp.new(:call, nil, :config)

  def initialize *args
    super
    @inside_config = false
  end

  #Use this method to process configuration file
  def process_config src, file_name
    @file_name = file_name
    res = Brakeman::AliasProcessor.new(@tracker).process_safely(src, nil, @file_name)
    process res
  end

  #Look for MyApp::Application.configure do ... end
  def process_iter exp
    call = exp.block_call

    if node_type?(call.target, :colon2) and
      call.target.rhs == :Application and
      call.method == :configure

      @inside_config = true
      process exp.block if sexp? exp.block
      @inside_config = false
    end

    exp
  end

  #Look for class Application < Rails::Application
  def process_class exp
    if exp.class_name == :Application
      @inside_config = true
      process_all exp.body if sexp? exp.body
      @inside_config = false
    end

    exp
  end

  #Look for configuration settings
  def process_attrasgn exp
    return exp unless @inside_config

    if exp.target == RAILS_CONFIG
      #Get rid of '=' at end
      attribute = exp.method.to_s[0..-2].to_sym
      if exp.args.length > 1
        #Multiple arguments?...not sure if this will ever happen
        @tracker.config.rails[attribute] = exp.args
      else
        @tracker.config.rails[attribute] = exp.first_arg
      end
    elsif include_rails_config? exp
      options = get_rails_config exp
      level = @tracker.config.rails
      options[0..-2].each do |o|
        level[o] ||= {}

        option = level[o]

        if not option.is_a? Hash
          Brakeman.debug "[Notice] Skipping config setting: #{options.map(&:to_s).join(".")}"
          return exp
        end

        level = level[o]
      end

      level[options.last] = exp.first_arg
    end

    exp
  end

  #Check if an expression includes a call to set Rails config
  def include_rails_config? exp
    target = exp.target
    if call? target
      if target.target == RAILS_CONFIG
        true
      else
        include_rails_config? target
      end
    elsif target == RAILS_CONFIG
      true
    else
      false
    end
  end

  #Returns an array of symbols for each 'level' in the config
  #
  #  config.action_controller.session_store = :cookie
  #
  #becomes
  #
  #  [:action_controller, :session_store]
  def get_rails_config exp
    if node_type? exp, :attrasgn
      attribute = exp.method.to_s[0..-2].to_sym
      get_rails_config(exp.target) << attribute
    elsif call? exp
      if exp.target == RAILS_CONFIG
        [exp.method]
      else
        get_rails_config(exp.target) << exp.method
      end
    else
      raise "WHAT"
    end
  end
end
