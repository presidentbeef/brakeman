require 'brakeman/checks/base_check'
require 'brakeman/processors/lib/processor_helper'

#Checks for user input in methods which open or manipulate files
class Brakeman::CheckFileAccess < Brakeman::BaseCheck
  Brakeman::Checks.add self

  def run_check
    methods = tracker.find_call [:Dir, :File, :IO, :Kernel, :"Net::FTP", :"Net::HTTP", :PStore, :Pathname, :Shell, :YAML], [:[], :chdir, :chroot, :delete, :entries, :foreach, :glob, :install, :lchmod, :lchown, :link, :load, :load_file, :makedirs, :move, :new, :open, :read, :read_lines, :rename, :rmdir, :safe_unlink, :symlink, :syscopy, :sysopen, :truncate, :unlink]

    methods.concat tracker.find_call [], [:load]

    methods.concat tracker.find_call(:FileUtils, nil)

    methods.each do |call|
      process_result call
    end
  end

  def process_result result
    call = result[-1]

    file_name = call[3][1]

    if check = include_user_input?(file_name)
      unless duplicate? call, result[1]
        add_result call, result[1]

        if check == :params
          message = "Parameter"
        elsif check == :cookies
          message = "Cookie"
        else
          message = "User input"
        end

        message << " value used in file name"

        warn :result => result,
          :warning_type => "File Access",
          :message => message, 
          :confidence => CONFIDENCE[:high],
          :line => call.line,
          :code => call
      end
    end
  end
end
