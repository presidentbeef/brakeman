class AccountController < ApplicationController
  def some_action
    Account.new params[:account]
  end
end
