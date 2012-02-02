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

    @tracker.find_call(:target => false, :method => :redirect_to).each do |res|
      process_result res
    end
  end

  def process_result result
    call = result[:call]

    method = call[2]

    if method == :redirect_to and not only_path?(call) and res = include_user_input?(call)
      if res == :immediate
        confidence = CONFIDENCE[:high]
      else
        confidence = CONFIDENCE[:low]
      end

      warn :result => result,
        :warning_type => "Redirect",
        :message => "Possible unprotected redirect",
        :line => call.line,
        :code => call,
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
      call[3][1][2] == :new and call[3][1][1]

      begin
        target = class_name call[3][1][1]
        if @tracker.models.include? target
          return false
        end
      rescue
      end
    end

    call[3].each do |arg|
      if call? arg 
        if ALL_PARAMETERS.include? arg or arg[2] == COOKIES 
          return :immediate
        elsif arg[2] == :url_for and include_user_input? arg
          return :immediate
          #Ignore helpers like some_model_url?
        elsif arg[2].to_s =~ /_(url|path)$/
          return false
        end
      elsif params? arg or cookies? arg
        return :immediate
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
        hash_iterate(arg) do |k,v|
          if symbol? k and k[1] == :only_path and v.is_a? Sexp and v[0] == :true
            return true
          end
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
        hash_iterate(arg) do |k,v|
          if symbol? k and k[1] == :only_path and v.is_a? Sexp and v[0] == :false
            return false
          end
        end
      end
    end

    true
  end
end
