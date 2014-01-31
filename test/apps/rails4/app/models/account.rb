class Account < ActiveRecord::Base
  attr_accessible :name, :account_id, :admin

  def sql_it_up_yeah
    connection.exec_update "UPDATE `purchases` SET type = '#{self.type}' WHERE id = '#{self.id}'"

    sql = "UPDATE #{self.class.table_name} SET latest_version = #{version} where id = #{self.id}"
    self.class.connection.execute sql
  end

  def self.more_sql_connection
    self.connection.exec_query "UPDATE `purchases` SET type = '#{self.type}' WHERE id = '#{self.id}'"
  end

  def safe_sql_should_not_warn
    self.class.connection.execute "DESCRIBE  #{self.business_object.table_name}"
    connection.select_one "SELECT * FROM somewhere WHERE x=#{connection.quote(params[:x])}"
    connection.execute "DELETE FROM stuff WHERE id=#{self.id}"
  end
end
