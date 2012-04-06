class Account < ActiveRecord::Base
  validates_format_of :name, :with => /^[a-zA-Z]+$/
  validates_format_of :blah, :with => /\A[a-zA-Z]+$/
  validates_format_of :something, :with => /[a-zA-Z]\z/
  validates_format_of :good_valid, :with => /\A[a-zA-Z]\z/ #No warning
  validates_format_of :not_bad, :with => /\A[a-zA-Z]\Z/ #No warning

  def mass_assign_it
    Account.new(params[:account_info]).some_other_method
  end

  def test_class_eval
    #Should not raise a warning
    User.class_eval do
      attr_reader :some_private_thing
    end
  end
end
