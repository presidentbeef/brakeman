class User < ActiveRecord::Base
  attr_accessible :bio, :name, :account_id, :admin, :status_id 
end
