class Group < ApplicationRecord
  def uuid_in_sql
    ActiveRecord::Base.connection.exec_query("select * where x = #{User.uuid}")
  end

  def date_in_sql
    date = 30.days.ago
    Arel.sql("created_at > '#{date}'")
  end
end
