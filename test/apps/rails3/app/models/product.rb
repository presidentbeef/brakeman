class Product < ActiveRecord::Base
  serialize :price
  attr_protected :price
end
