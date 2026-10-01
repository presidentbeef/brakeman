class Comment < ApplicationRecord
  belongs_to :author, class_name: 'User', optional: true
  belongs_to :project, optional: true
end
