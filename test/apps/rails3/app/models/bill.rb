class Bill < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
end
