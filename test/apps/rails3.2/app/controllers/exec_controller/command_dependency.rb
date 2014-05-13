class ExecController

  def exec_this
    `ls #{params[:file_name]}`

    system params[:user_input]
  end

end
