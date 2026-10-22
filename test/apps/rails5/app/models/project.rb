class Project < ApplicationRecord
  belongs_to :archived_by, class_name: 'User', optional: true
  belongs_to :tenant
end
