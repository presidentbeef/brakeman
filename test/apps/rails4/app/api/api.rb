module API

  def insecure_command_execution
    Open3.capture2 "ls #{params[:dir]}"
  end
end
