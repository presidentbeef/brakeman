class EmailsController < ApplicationController
  def show
    @email = Email.find params[:email_id]
  end
end
