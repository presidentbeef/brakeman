class UsersController < ApplicationController
  def redirect_to_last!
    redirect_to User.last!
  end

  def presence
    # Don't warn... @field is either "foo" or nil
    @field = params[:field].presence_in(%w[foo]) || raise(ActionController::BadRequest)
    render "admin2/fields/#{@field}"
  end
end
