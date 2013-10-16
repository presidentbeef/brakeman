require 'brakeman/checks/base_check'

#Reports any calls to +redirect_to+ which include parameters in the arguments.
#
#For example:
#
# redirect_to params.merge(:action => :elsewhere)
class Brakeman::CheckRedirect < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Looks for calls to redirect_to with user input as arguments"

  def run_check
    Brakeman.debug "Finding calls to redirect_to()"

    @model_find_calls = Set[:all, :find, :find_by_sql, :first, :last, :new]

    if tracker.options[:rails3]
      @model_find_calls.merge [:from, :group, :having, :joins, :lock, :order, :reorder, :select, :where]
    end

    @tracker.find_call(:target => false, :method => :redirect_to).each do |res|
      process_result res
    end
  end

  def process_result result
    return if duplicate? result

    call = result[:call]

    method = call.method

    if method == :redirect_to and not only_path?(call) and res = include_user_input?(call)
      add_result result

      if res.type == :immediate
        confidence = CONFIDENCE[:high]
      else
        confidence = CONFIDENCE[:low]
      end

      warn :result => result,
        :warning_type => "Redirect",
        :warning_code => :open_redirect,
        :message => "Possible unprotected redirect",
        :code => call,
        :user_input => res.match,
        :confidence => confidence
    end
  end

  #Custom check for user input. First looks to see if the user input
  #is being output directly. This is necessary because of tracker.options[:check_arguments]
  #which can be used to enable/disable reporting output of method calls which use
  #user input as arguments.
  def include_user_input? call, immediate = :immediate
    Brakeman.debug "Checking if call includes user input"

    arg = call.first_arg

    # if the first argument is an array, rails assumes you are building a
    # polymorphic route, which will never jump off-host
    return false if array? arg

    if tracker.options[:ignore_redirect_to_model]
      if model_instance?(arg) or decorated_model?(arg)
        return false
      end
    end

    if res = has_immediate_model?(arg)
      return Match.new(immediate, res)
    elsif call? arg
      if request_value? arg
        return Match.new(immediate, arg)
      elsif request_value? arg.target
        return Match.new(immediate, arg.target)
      elsif arg.method == :url_for and include_user_input? arg
        return Match.new(immediate, arg)
        #Ignore helpers like some_model_url?
      elsif arg.method.to_s =~ /_(url|path)\z/
        return false
      end
    elsif request_value? arg
      return Match.new(immediate, arg)
    end

    if tracker.options[:check_arguments] and call? arg
      include_user_input? arg, false  #I'm doubting if this is really necessary...
    else
      false
    end
  end

  #Checks +redirect_to+ arguments for +only_path => true+ which essentially
  #nullifies the danger posed by redirecting with user input
  def only_path? call
    arg = call.first_arg

    if hash? arg
      if value = hash_access(arg, :only_path)
        return true if true?(value)
      end
    elsif call? arg and arg.method == :url_for
      return check_url_for(arg)
    end

    false
  end

  #+url_for+ is only_path => true by default. This checks to see if it is
  #set to false for some reason.
  def check_url_for call
    arg = call.first_arg

    if hash? arg
      if value = hash_access(arg, :only_path)
        return false if false?(value)
      end
    end

    true
  end

  #Returns true if exp is (probably) a model instance
  def model_instance? exp
    if node_type? exp, :or
      model_instance? exp.lhs or model_instance? exp.rhs
    elsif call? exp
      if model_name? exp.target or friendly_model? exp.target and
        (@model_find_calls.include? exp.method or exp.method.to_s.match(/^find_by_/))
        true
      else
        association?(exp.target, exp.method)
      end
    end
  end

  #Returns true if exp is (probably) a friendly model instance
  #using the FriendlyId gem
  def friendly_model? exp
    call? exp and model_name? exp.target and exp.method == :friendly
  end
  
  #Returns true if exp is (probably) a decorated model instance
  #using the Draper gem
  def decorated_model? exp
    if node_type? exp, :or
      decorated_model? exp.lhs or decorated_model? exp.rhs
    else
      tracker.config[:gems] and
      tracker.config[:gems][:draper] and
      call? exp and
      node_type?(exp.target, :const) and
      exp.target.value.to_s.match(/Decorator$/) and
      exp.method == :decorate
    end
  end

  #Check if method is actually an association in a Model
  def association? model_name, meth
    if call? model_name
      return association? model_name.target, meth
    elsif model_name? model_name
      model = tracker.models[class_name(model_name)]
    else
      return false
    end

    return false unless model

    model[:associations].each do |name, args|
      args.each do |arg|
        if symbol? arg and arg.value == meth
          return true
        end
      end
    end

    false
  end
end
