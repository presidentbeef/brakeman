if OPTIONS[:rails3]
  load 'brakeman/processors/lib/rails3_config_processor.rb'
else
  load 'brakeman/processors/lib/rails2_config_processor.rb'
end
