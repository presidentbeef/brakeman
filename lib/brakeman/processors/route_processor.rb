require 'brakeman/processors/base_processor'
require 'brakeman/processors/alias_processor'
require 'brakeman/processors/lib/route_helper'
require 'brakeman/util'
require 'set'

if OPTIONS[:rails3]
  load 'brakeman/processors/lib/rails3_route_processor.rb'
else
  load 'brakeman/processors/lib/rails2_route_processor.rb'
end
