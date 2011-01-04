require 'processors/base_processor'
require 'processors/alias_processor'
require 'lib/processors/lib/route_helper'
require 'util'
require 'set'

if OPTIONS[:rails3]
  require 'lib/processors/rails3_route_processor'
else
  require 'lib/processors/rails2_route_processor'
end
