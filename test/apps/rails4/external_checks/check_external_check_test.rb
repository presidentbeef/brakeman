require 'brakeman/checks/base_check'

#Verify that checks external to the checks/ dir are added by the additional_checks_path options flag
class Brakeman::CheckExternalCheckTest < Brakeman::BaseCheck
  Brakeman::Checks.add_optional self

  @description = "An external check that does nothing, used for testing"

  def run_check
  end
end
