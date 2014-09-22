class ExecController
  def inner_exec
    system params[:user_input]
  end
end
