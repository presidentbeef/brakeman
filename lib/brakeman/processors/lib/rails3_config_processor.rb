Brakeman::RAILS_CONFIG = Sexp.new(:call, nil, :config, Sexp.new(:arglist))
  
#Processes configuration. Results are put in tracker.config.
#
#Configuration of Rails via Rails::Initializer are stored in tracker.config[:rails].
#For example:
#
#  MyApp::Application.configure do
#    config.active_record.whitelist_attributes = true
#  end
#
#will be stored in
#
#  tracker.config[:rails][:active_record][:whitelist_attributes]
#
#Values for tracker.config[:rails] will still be Sexps.
class Brakeman::Rails3ConfigProcessor < Brakeman::BaseProcessor
  def initialize *args
    super
    @tracker.config[:rails] ||= {}
    @inside_config = false
  end

  #Use this method to process configuration file
  def process_config src
    res = Brakeman::AliasProcessor.new(@tracker).process_safely(src)
    process res
  end

  #Look for MyApp::Application.configure do ... end
  def process_iter exp
    if sexp?(exp[1][1]) and exp[1][1][0] == :colon2 and exp[1][1][2] == :Application
      @inside_config = true
      process exp[-1] if sexp? exp[-1]
      @inside_config = false
    end

    exp
  end

  #Look for class Application < Rails::Application
  def process_class exp
    if exp[1] == :Application
      @inside_config = true
      process exp[-1] if sexp? exp[-1]
      @inside_config = false
    end

    exp
  end

  #Look for configuration settings
  def process_attrasgn exp
    return exp unless @inside_config

    if exp[1] == Brakeman::RAILS_CONFIG
      #Get rid of '=' at end
      attribute = exp[2].to_s[0..-2].to_sym
      if exp[3].length > 2
        #Multiple arguments?...not sure if this will ever happen
        @tracker.config[:rails][attribute] = exp[3][1..-1]
      else
        @tracker.config[:rails][attribute] = exp[3][1]
      end
    elsif include_rails_config? exp
      options = get_rails_config exp
      level = @tracker.config[:rails]
      options[0..-2].each do |o|
        level[o] ||= {}
        level = level[o]
      end

      level[options.last] = exp[3][1]
    end

    exp
  end

  #Check if an expression includes a call to set Rails config
  def include_rails_config? exp
    target = exp[1]
    if call? target
      if target[1] == Brakeman::RAILS_CONFIG
        true
      else
        include_rails_config? target
      end
    elsif target == Brakeman::RAILS_CONFIG
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
    if sexp? exp and exp.node_type == :attrasgn
      attribute = exp[2].to_s[0..-2].to_sym
      get_rails_config(exp[1]) << attribute
    elsif call? exp
      if exp[1] == Brakeman::RAILS_CONFIG
        [exp[2]]
      else
        get_rails_config(exp[1]) << exp[2]
      end
    else
      raise "WHAT"
    end
  end
end
