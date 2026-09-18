class Phone < ActiveRecord::Base
  PHONE_NUMBER_REGEXP = %r{
    \A
    +\d+ # counter prefix
    \ * # space
    \(\d+\) # city code
    \ * # space
    (\d+-)*\d+
    \z
  }x
  validates_format_of :number, with: PHONE_NUMBER_REGEXP
  validates_format_of :number, with: /\A(?!.*123456789)/m # should not contain many digits ascending, may be fake
  validates_format_of :number, with: /\A(?!.*987654321)/m # should not contain many digits descending, may be fake
end
