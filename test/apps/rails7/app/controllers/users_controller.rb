class UsersController < ApplicationController
  def redirect_to_last!
    redirect_to User.last!
  end

  def presence
    # Don't warn... @field is either "foo" or nil
    @field = params[:field].presence_in(%w[foo]) || raise(ActionController::BadRequest)
    render "admin2/fields/#{@field}"
  end

  def redirect_param_with_fallback
    redirect_to params[:redirect_url] || "/"
  end

  def redirect_url_from_param_with_fallback
    redirect_to url_from(params[:redirect_url]) || "/"
  end

  def redirect_with_allow_host
    redirect_to params[:x], allow_other_host: true # low confidence warning
  end

  def redirect_with_explicit_not_allow
    redirect_to params[:x], allow_other_host: false # no warning
  end

  def redirect_back_with_fallback
    redirect_back fallback_location: params[:x]
  end

  def redirect_back_or_to_with_fallback
    redirect_back_or_to params[:x]
  end

  def redirect_back_or_to_with_fallback_disallow_host
    redirect_back_or_to params[:x], allow_other_host: false # no warning
  end
end
