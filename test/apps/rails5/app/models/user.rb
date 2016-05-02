class User < ApplicationRecord
  def test_stuff
    if Rails.env.test?
      User.where(params)
    end
  end
end
