class Group < ApplicationRecord
  def uuid_in_sql
    ActiveRecord::Base.connection.exec_query("select * where x = #{User.uuid}")
  end

  def date_in_sql
    date = 30.days.ago
    Arel.sql("created_at > '#{date}'")
  end

  def ar_sanitize_sql_like(query)
    query = ActiveRecord::Base.sanitize_sql_like(query) # escaped variable
    Arel.sql("name ILIKE '%#{query}%'")
  end

  def fetch_constant_hash_value(role_name)
    roles = { admin: 1, moderator: 2 }.freeze
    role = roles.fetch(role_name)
    Arel.sql("role = '#{role}'")
  end

  def use_simple_method
    # No warning
    self.where("thing = #{Group.simple_method}")
  end

  def self.simple_method
    "Hello"
  end

  enum status: { start: 0, stop: 2, in_process: 3 }

  def use_enum
    # No warning
    self.where("thing IN #{Group.statuses.values_at(*[:start, :stop]).join(',')}")
  end
end
