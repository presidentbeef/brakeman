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

    method = call[2]

    if method == :redirect_to && !only_path?(call) && res = include_user_input?(call)
      add_result result

      if res.type == :immediate || res.type == :params
        confidence = CONFIDENCE[:high]
      else
        confidence = CONFIDENCE[:low]
      end

      if message_string_interpolation_from_params? res
        warning_type = "Cross Site Scripting"
        message = "Notice or error message interpolates input from params"
      else
        warning_type = "Redirect"
        message = "Possible unprotected redirect"
      end

      warn( :result => result,
        :warning_type => warning_type,
        :message => message,
        :code => call,
        :user_input => res.match,
        :confidence => confidence)

    end
  end

  #Custom check for user input. First looks to see if the user input
  #is being output directly. This is necessary because of tracker.options[:check_arguments]
  #which can be used to enable/disable reporting output of method calls which use
  #user input as arguments.
  def include_user_input? call
    Brakeman.debug "Checking if call includes user input"

    args = call[3]

    if tracker.options[:ignore_redirect_to_model] and call? args[1] and
      (@model_find_calls.include? args[1][2] or args[1][2].to_s.match(/^find_by_/)) and
      model_name? args[1][1]

      return false
    end

    if hash? args[-1]
      [:notice, :error].each do |alert_type|
        if hash_access(args[-1], alert_type)
          super_match = super(hash_access(args[-1], alert_type))
          return Match.new(super_match.type, args[-1]) if super_match.type == :params
        end
      end
    end

    args.each do |arg|
      if res = has_immediate_model?(arg)
        return Match.new(:immediate, res)
      elsif call? arg
        if request_value? arg
          return Match.new(:immediate, arg)
        elsif request_value? arg[1]
          return Match.new(:immediate, arg[1])
        elsif arg[2] == :url_for and include_user_input? arg
          return Match.new(:immediate, arg)
          #Ignore helpers like some_model_url?
        elsif arg[2].to_s =~ /_(url|path)$/
          return false
        end
      elsif request_value? arg
        return Match.new(:immediate, arg)
      end
    end

    if tracker.options[:check_arguments]
      super
    else
      false
    end
  end

  #Checks +redirect_to+ arguments for +only_path => true+ which essentially
  #nullifies the danger posed by redirecting with user input
  def only_path? call
    call[3].each do |arg|
      if hash? arg
        if value = hash_access(arg, :only_path)
          return true if true?(value)
        end
      elsif call? arg and arg[2] == :url_for
        return check_url_for(arg)
      end
    end

    false
  end

  #+url_for+ is only_path => true by default. This checks to see if it is
  #set to false for some reason.
  def check_url_for call
    call[3].each do |arg|
      if hash? arg
        if value = hash_access(arg, :only_path)
          return false if false?(value)
        end
      end
    end

    true
  end

  def message_string_interpolation_from_params? res
    res.type == :params &&
      ( hash_access(res.match, :notice) && node_type?(hash_access(res.match, :notice), :string_interp) ||
        hash_access(res.match, :error)  && node_type?(hash_access(res.match, :error),  :string_interp) )
  end
end
