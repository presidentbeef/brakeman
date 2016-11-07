module ForgeryProtection
  extend ActiveSupport::Concern

  included do
    protect_from_forgery with: :exception
  end
end
