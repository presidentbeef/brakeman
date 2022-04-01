class ApplicationController < ActionController::Base
  def anonymouns_block_argument(&)
    Time.use_zone('CET', &)
  end

  def hash_value_omission
    x = 1
    y = 2

    {x:, y:}
  end

  def endless_method_definition(msg) = puts "#{Time.now}: #{msg}"

  def pattern_matching_parenthesis_ommission
    [0, 1] => _, x
    {y: 2} => y:

    {x:, y:}
  end

  def pattern_matching_non_local_variable_pin
    {timestamp: Time.now} in {timestamp: ^(Time.new(2021)..Time.new(2022))}
  end
end
