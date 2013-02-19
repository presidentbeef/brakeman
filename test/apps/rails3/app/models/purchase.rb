class Purchase < ActiveRecord::Base
  attr_accessible
  serialize :something
end
