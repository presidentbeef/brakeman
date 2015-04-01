class User < ActiveRecord::Base
  attr_accessible :name

  scope :tall, lambda {|*args| where("height > '#{User.average_height}'") }

  scope :blah, where("thinger = '#{BLAH}'") #No longer warns on constants

  scope :dah, lambda {|*args| { :conditions => "dah = '#{args[1]}'"}}
  
  scope :phooey, :conditions => "phoeey = '#{User.phooey}'"

  scope :this_is_safe, lambda { |name|
    where("name = ?", "%#{name.downcase}%")
  }

  scope :this_is_also_safe, where("name = ?", "%#{name.downcase}%")

  scope :should_not_warn, :conditions => ["name = ?", "%#{name.downcase}%"]

  scope :unsafe_multiline_scope, lambda {
    something = something_helper
    where("something = #{something}")
  }

  scope :all

  belongs_to :account

  attr_accessible :admin, :as => :admin

  def self.sql_stuff parent_id
    condition = parent_id.blank? ? " IS NULL" : " = #{parent_id}"
    self.connection.select_values("SELECT max(id) FROM content_pages WHERE parent_content_page_id #{condition}")[0].to_i
    self.connection.select_values("SELECT max(id) FROM content_pages WHERE child_content_page_id #{child_id}")[0].to_i

    # Should not warn
    User.where("#{table_name}.visibility = ?" +
               " OR (#{table_name}.visibility = ? AND #{table_name}.id IN (" +
               "SELECT DISTINCT a.id FROM #{table_name} a" +
               " INNER JOIN #{User.table_name} m ON m.id = mr.member_id AND m.user_id = ?" +
               " WHERE a.project_id IS NULL OR a.project_id = m.project_id))" +
               " OR #{table_name}.user_id = ?",
                 stuff, stuff, user.id, user.id)
  end

  def self.safe_sql_using_quoted_table_name
    where("#{User.quoted_table_name}.id = ?", 1)
  end

  def self.more_safe_stuff
    where("#{User.primary_key} = #{table_name_prefix}a.thing")
  end
end
