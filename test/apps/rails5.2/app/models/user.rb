class User < ActiveRecord::Base
  def not_something thing
    where.not("blah == #{thing}")
  end
end
