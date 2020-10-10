class Widget < ApplicationRecord
  def spin(direction)
    where("direction = #{direction})").first.spin
  end
end
