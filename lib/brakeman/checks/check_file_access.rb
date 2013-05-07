require 'brakeman/checks/base_check'
require 'brakeman/processors/lib/processor_helper'

#Checks for user input in methods which open or manipulate files
class Brakeman::CheckFileAccess < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Finds possible file access using user input"

  def run_check
    Brakeman.debug "Finding possible file access"
    methods = tracker.find_call :targets => [:Dir, :File, :IO, :Kernel, :"Net::FTP", :"Net::HTTP", :PStore, :Pathname, :Shell], :methods => [:[], :chdir, :chroot, :delete, :entries, :foreach, :glob, :install, :lchmod, :lchown, :link, :load, :load_file, :makedirs, :move, :new, :open, :read, :readlines, :rename, :rmdir, :safe_unlink, :symlink, :syscopy, :sysopen, :truncate, :unlink]

    methods.concat tracker.find_call :target => :YAML, :methods => [:load_file, :parse_file]

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
    return if duplicate? result
    add_result result
    call = result[:call]
    file_name = call.first_arg

    if match = has_immediate_user_input?(file_name)
      confidence = CONFIDENCE[:high]
    elsif match = has_immediate_model?(file_name)
      match = Match.new(:model, match)
      confidence = CONFIDENCE[:med]
    elsif tracker.options[:check_arguments] and
      match = include_user_input?(file_name)

      #Check for string building in file name
      if call?(file_name) and (file_name.method == :+ or file_name.method == :<<)
        confidence = CONFIDENCE[:high]
      else
        confidence = CONFIDENCE[:low]
      end
    end

    if match
      message = "#{friendly_type_of(match).capitalize} used in file name"

      warn :result => result,
        :warning_type => "File Access",
        :warning_code => :file_access,
        :message => message,
        :confidence => confidence,
        :code => call,
        :user_input => match.match
    end
  end
end
