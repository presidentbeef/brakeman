require 'brakeman/checks/base_check'

class Brakeman::CheckExternalCheckConfigTest < Brakeman::BaseCheck
  Brakeman::Checks.add_optional self

  @description = "An external check for testing"

  def run_check
    raise "This should not have been loaded!"
  end
end
