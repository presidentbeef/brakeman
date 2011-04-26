require 'processors/base_processor'
require 'processors/alias_processor'
require 'processors/lib/route_helper'
require 'util'
require 'set'

if OPTIONS[:rails3]
  require 'processors/lib/rails3_route_processor'
else
  require 'processors/lib/rails2_route_processor'
end
