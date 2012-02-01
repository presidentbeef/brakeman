class User < ActiveRecord::Base
  attr_accessible :name

  scope :tall, lambda {|*args| where("height > '#{User.average_height}'") }

  scope :blah, where("thinger = '#{BLAH}'")

  scope :dah, lambda {|*args| { :condition => "dah = '#{args[1]}'"}}
  
  scope :phooey, :condition => "phoeey = '#{User.phooey}'"

  scope :this_is_safe, lambda { |name|
    where("name = ?", "%#{name.downcase}%")
  }

  scope :this_is_also_safe, where("name = ?", "%#{name.downcase}%")

  scope :should_not_warn, :condition => ["name = ?", "%#{name.downcase}%"]
end
