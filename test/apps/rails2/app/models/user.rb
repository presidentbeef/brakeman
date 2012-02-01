class User < ActiveRecord::Base
  named_scope :dah, lambda {|*args| { :condition => "dah = '#{args[1]}'"}}
  
  named_scope :phooey, :condition => "phoeey = '#{User.phooey}'"

  named_scope :with_state, lambda {|state| state.present? ? {:conditions => "state_name = '#{state}'"} : {}}

  named_scope :safe_phooey, :condition => ["phoeey = ?", "#{User.phooey}"]

  named_scope :safe_dah, lambda {|*args| { :condition => ["dah = ?", "#{args[1]}"]}}

  named_scope :with_state, lambda {|state| state.present? ? {:conditions => ["state_name = ?", "#{state}"]} : {}}
end
