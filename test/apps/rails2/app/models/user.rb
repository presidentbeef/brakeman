class User < ActiveRecord::Base
  named_scope :dah, lambda {|*args| { :conditions => "dah = '#{args[1]}'"}}
  
  named_scope :phooey, :conditions => "phoeey = '#{User.phooey}'"

  named_scope :with_state, lambda {|state| state.present? ? {:conditions => "state_name = '#{state}'"} : {}}

  named_scope :safe_phooey, :conditions => ["phoeey = ?", "#{User.phooey}"]

  named_scope :safe_dah, lambda {|*args| { :conditions => ["dah = ?", "#{args[1]}"]}}

  named_scope :with_state, lambda {|state| state.present? ? {:conditions => ["state_name = ?", "#{state}"]} : {}}

  def get_something x
    self.find(:all, :conditions => "where blah = #{x}")
  end

  def test_merge_conditions
    #Should not warn
    User.find(:all, :conditions => merge_conditions(some_conditions))
    User.find(:all, :conditions => self.merge_conditions(some_conditions))
    find(:all, :conditions => User.merge_conditions(some_conditions))
  end

  def self.some_method(value)
    results = ActiveRecord::Base.connection.execute(%Q(SELECT
        id
      FROM
        table t
      WHERE
        t.something = '#{value}'))
  end

  def self.test_sanitized_sql input
    self.connection.select_all("select * from cool_table where stuff = " + self.sanitize_sql(input))
  end

  def more_sanitized_sql
    self.connection.execute("DELETE FROM cool_table WHERE cool_id=" + quote_value(self.cool_id) + "  AND my_id=" + quote_value(self.id))
  end
end
