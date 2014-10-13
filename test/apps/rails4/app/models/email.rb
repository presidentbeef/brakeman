class Email < ActiveRecord::Base
  attr_accessible :email

  belongs_to :user
end
