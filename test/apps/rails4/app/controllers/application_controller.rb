class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def show_detailed_exceptions?
    true
  end

  def redirect_to_created_model
    if create
      @model = User.create
      @model.save!
      redirect_to @model
    else
      @model = User.create!
      @model.save
      redirect_to @model
    end
  end

  def bypass_ssl_check
    # Should warn on self.verify_mode = OpenSSL::SSL::VERIFY_NONE
    self.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
end
