if OPTIONS[:rails3]
  load 'processors/lib/rails3_config_processor.rb'
else
  load 'processors/lib/rails2_config_processor.rb'
end
