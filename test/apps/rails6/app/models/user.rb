class User < ApplicationRecord
  def self.render_user_input
    ERB.new(params)
  end
end
