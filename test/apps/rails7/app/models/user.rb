class User < ApplicationRecord
  belongs_to :matched_user, class_name: 'User', optional: true
end
