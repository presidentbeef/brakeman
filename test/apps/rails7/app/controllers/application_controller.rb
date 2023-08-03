class ApplicationController < ActionController::Base
  def anonymouns_arguments(*, **, &)
    Time.use_zone(*, **, &)
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

  def pathname_stuff
    z = Pathname.new('a').join(params[:x], 'z').basename # should warn
    something(z) # should not be a duplicate warning

    Rails.root.join('a', 'b', "#{params[:c]}") # should warn
  end
end
