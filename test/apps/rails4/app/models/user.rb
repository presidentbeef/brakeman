class User < ActiveRecord::Base
  def test_sql_sanitize(x)
    self.select("#{sanitize(x)}")
  end
end
