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
end
