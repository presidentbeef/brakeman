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
end
