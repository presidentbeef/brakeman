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

    if method == :redirect_to and not only_path?(call) and res = include_user_input?(call)
      add_result result

      if res.type == :immediate
        confidence = CONFIDENCE[:high]
      else
        confidence = CONFIDENCE[:low]
      end

      warn :result => result,
        :warning_type => "Redirect",
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
  def include_user_input? call
    Brakeman.debug "Checking if call includes user input"

    if tracker.options[:ignore_redirect_to_model] and call? call[3][1] and 
      @model_find_calls.include? call[3][1][2] and model_name? call[3][1][1]

      return false
    end

    call[3].each do |arg|
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
end
