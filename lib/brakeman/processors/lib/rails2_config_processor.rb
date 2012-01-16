#Replace block variable in
#
#  Rails::Initializer.run |config|
#
#with this value so we can keep track of it.
Brakeman::RAILS_CONFIG = Sexp.new(:const, :"!BRAKEMAN_RAILS_CONFIG") unless defined? Brakeman::RAILS_CONFIG

#Processes configuration. Results are put in tracker.config.
#
#Configuration of Rails via Rails::Initializer are stored in tracker.config[:rails].
#For example:
#
#  Rails::Initializer.run |config|
#    config.action_controller.session_store = :cookie_store
#  end
#
#will be stored in
#
#  tracker.config[:rails][:action_controller][:session_store]
#
#Values for tracker.config[:rails] will still be Sexps.
class Brakeman::Rails2ConfigProcessor < Brakeman::BaseProcessor
  def initialize *args
    super
    @tracker.config[:rails] ||= {}
  end

  #Use this method to process configuration file
  def process_config src
    res = Brakeman::ConfigAliasProcessor.new.process_safely(src)
    process res
  end

  #Check if config is set to use Erubis
  def process_call exp
    target = exp[1]
    target = process target if sexp? target

    if exp[2] == :gem and exp[3][1][1] == "erubis"
      Brakeman.notify "[Notice] Using Erubis for ERB templates"
      @tracker.config[:erubis] = true
    end

    exp
  end

  #Look for configuration settings
  def process_attrasgn exp
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

  #Check for Rails version
  def process_cdecl exp
    #Set Rails version required
    if exp[1] == :RAILS_GEM_VERSION
      @tracker.config[:rails_version] = exp[2][1]
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

#This is necessary to replace block variable so we can track config settings
class Brakeman::ConfigAliasProcessor < Brakeman::AliasProcessor

  RAILS_INIT = Sexp.new(:colon2, Sexp.new(:const, :Rails), :Initializer)

  #Look for a call to 
  #
  #  Rails::Initializer.run do |config|
  #    ...
  #  end
  #
  #and replace config with Brakeman::RAILS_CONFIG
  def process_iter exp
    target = exp[1][1]
    method = exp[1][2]

    if sexp? target and target == RAILS_INIT and method == :run
      exp[2][2] = Brakeman::RAILS_CONFIG
    end

    process_default exp
  end
end
