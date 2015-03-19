class User < ActiveRecord::Base
  def test_sql_sanitize(x)
    self.select("#{sanitize(x)}")
  end

  scope :hits_by_ip, ->(ip,col="*") { select("#{col}").order("id DESC") }

  def arel_exists
    where(User.where(User.arel_table[:object_id].eq(arel_table[:id])).exists)
  end

  def symbol_stuff
    self.where(User.table_name.to_sym)
  end

  def self.get_all_countries(locale)
    q = "country_#{locale} ASC".to_s
    c = User.order(q)
  end
end
