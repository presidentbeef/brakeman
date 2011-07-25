class Account < ActiveRecord::Base
  validates_format_of :name, :with => /^[a-zA-Z]+$/
  validates_format_of :blah, :with => /\A[a-zA-Z]+$/
  validates_format_of :something, :with => /[a-zA-Z]\z/
  validates_format_of :good_valid, :with => /\A[a-zA-Z]\z/ #No warning
  validates_format_of :not_bad, :with => /\A[a-zA-Z]\Z/ #No warning
end
