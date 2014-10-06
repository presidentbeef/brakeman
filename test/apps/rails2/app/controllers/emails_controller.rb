class EmailsController < ApplicationController
  def show
    @email = Email.find params[:email_id]
  end

  def show_email_1
    @email = Email.find 1
  end
end
