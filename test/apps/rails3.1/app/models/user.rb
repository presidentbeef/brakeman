class User < ActiveRecord::Base
  attr_accessible :name

  scope :tall, lambda {|*args| where("height > '#{User.average_height}'") }

  scope :blah, where("thinger = '#{BLAH}'")

  scope :dah, lambda {|*args| { :condition => "dah = '#{args[1]}'"}}
  
  scope :phooey, :condition => "phoeey = '#{User.phooey}'"
end
