class Thing < ApplicationRecord
  class << self
    def ransackable_associations(auth_object = nil)
      []
    end
  end
end
