require 'brakeman/checks/base_check'

# Check for detailed exceptions enabled for production
class Brakeman::CheckDetailedExceptions < Brakeman::BaseCheck
  Brakeman::Checks.add self

  LOCAL_REQUEST = s(:call, s(:call, nil, :request), :local?)

  @description = "Checks for information disclosure displayed via detailed exceptions"

  def run_check
    check_local_request_config
    check_detailed_exceptions
  end

  def check_local_request_config
    if true? tracker.config[:rails][:consider_all_requests_local]
      warn :warning_type => "Information Disclosure",
           :warning_code => :local_request_config,
           :message => "Detailed exceptions are enabled in production",
           :confidence => CONFIDENCE[:high],
           :file => "config/environments/production.rb"
    end
  end

  def check_detailed_exceptions
    tracker.controllers.each do |name, controller|
      controller[:public].each do |name, definition|
        src = definition[:src]
        body = src.body.last
        next unless body

        if name == :show_detailed_exceptions? and not safe? body
          if true? body
            confidence = CONFIDENCE[:high]
          else
            confidence = CONFIDENCE[:med]
          end

          warn :warning_type => "Information Disclosure",
               :warning_code => :detailed_exceptions,
               :message => "Detailed exceptions may be enabled in 'show_detailed_exceptions?'",
               :confidence => confidence,
               :code => src,
               :file => definition[:file]
        end
      end
    end
  end

  def safe? body
    false? body or
    body == LOCAL_REQUEST
  end
end
