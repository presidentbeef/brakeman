class Group < ApplicationRecord
  belongs_to :user, optional: true
end
