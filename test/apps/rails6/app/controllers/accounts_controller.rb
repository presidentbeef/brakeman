class AccountsController < ApplicationController
  def login
    if request.get?
      # Do something benign
    else
      # Do something sensitive because it's a POST
      # but actually it could be a HEAD :(
    end
  end

  def auth_something 
    # Does not warn because there is an elsif clause
    if request.get?
      # Do something benign
    elsif request.post?
      # Do something sensitive because it's a POST
    end

    if request.post?
      # Do something sensitive because it's a POST
    elsif request.get?
      # Do something benign
    end
  end
end
