class ExecController < ApplicationController
  require_dependency "exec_controller/command_dependency"

  def outer_exec
    system params[:user_input]
  end
end
