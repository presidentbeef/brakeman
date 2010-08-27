require 'checks/check_file_access'
require 'processors/lib/processor_helper'

#Checks for user input in send_file()
class CheckSendFile < CheckFileAccess
  Checks.add self

  def run_check
    methods = tracker.find_call nil, :send_file

    methods.each do |call|
      process_result call
    end
  end
end
