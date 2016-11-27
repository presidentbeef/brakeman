class BaseController < ActionController::Base
  # No protect_from_forgery call, but one mixed in
  include ForgeryProtection
end
