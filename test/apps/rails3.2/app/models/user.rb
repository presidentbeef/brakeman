class User < ActiveRecord::Base
  require_dependency "user/command_dependency"

  attr_accessible :bio, :name, :account_id, :admin, :status_id
end
