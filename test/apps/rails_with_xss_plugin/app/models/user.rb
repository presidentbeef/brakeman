class User < ActiveRecord::Base
  has_many :posts

  validates_uniqueness_of :user_name
  validates_format_of :user_name, :with => /^\w+$/
  validates_length_of :user_name, :maximum => 10
  validates_format_of :display_name, :with => /^(\w|\s)+$/
  validates_presence_of :user_name, :display_name, :password
end
