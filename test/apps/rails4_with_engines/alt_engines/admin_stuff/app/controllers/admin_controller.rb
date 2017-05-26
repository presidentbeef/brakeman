class AdminController < ApplicationController
  def debug
    params[:class].classify.constantize.send(params[:meth])
  end
end
