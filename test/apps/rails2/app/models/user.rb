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
end
