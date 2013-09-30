class Account < ActiveRecord::Base
  attr_accessible :plan_id, :banned 
end
