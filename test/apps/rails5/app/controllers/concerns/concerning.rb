module Concerning
  extend ActiveSupport::Concern

  included do
    include Concerning
  end
end
