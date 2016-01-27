class User < ActiveRecord::Base
  attr_accessible :bio, :name, :account_id, :admin, :status_id 

  accepts_nested_attributes_for :something, allow_destroy: false, reject_if: proc { |attributes| stuff }
end
