require 'brakeman/checks/base_check'
require 'brakeman/processors/lib/processor_helper'

#Checks for user input in methods which open or manipulate files
class Brakeman::CheckFileAccess < Brakeman::BaseCheck
  Brakeman::Checks.add self

  def run_check
    Brakeman.debug "Finding possible file access"
    methods = tracker.find_call :targets => [:Dir, :File, :IO, :Kernel, :"Net::FTP", :"Net::HTTP", :PStore, :Pathname, :Shell, :YAML], :methods => [:[], :chdir, :chroot, :delete, :entries, :foreach, :glob, :install, :lchmod, :lchown, :link, :load, :load_file, :makedirs, :move, :new, :open, :read, :read_lines, :rename, :rmdir, :safe_unlink, :symlink, :syscopy, :sysopen, :truncate, :unlink]

    Brakeman.debug "Finding calls to load()"
    methods.concat tracker.find_call :target => false, :method => :load

    Brakeman.debug "Finding calls using FileUtils"
    methods.concat tracker.find_call :target => :FileUtils

    Brakeman.debug "Processing found calls"
    methods.each do |call|
      process_result call
    end
  end

  def process_result result
    call = result[:call]

    file_name = call[3][1]

    if check = include_user_input?(file_name)
      unless duplicate? result
        add_result result

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
