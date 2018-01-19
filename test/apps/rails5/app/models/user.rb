class User < ApplicationRecord
  def self.evaluate_user_input
    eval(params)
  end

  def evaluate_user_input
    self.class.evaluate_user_input
  end

  def test_stuff
    if Rails.env.test?
      User.where(params)
    end
  end

  has_many :things,
    -> { where(Thing.canadian.where_values_hash) }

  def self.all_that_jazz(user)
    User.where(User.access_condition(user))
  end

  belongs_to :matched_user, class_name: 'User', optional: true
end
