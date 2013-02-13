class Account < ActiveRecord::Base
  validates :username, :length => 6..20, :format => /([a-z][0-9])+/i
  validates :phone, :format => { :with => /(\d{3})-(\d{3})-(\d{4})/, :on => :create }, :presence => true 
  validates :first_name, :format => /\w+/
  serialize :cc_info #safe from CVE-2013-0277
end
