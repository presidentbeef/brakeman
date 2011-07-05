require "active_support/core_ext"
module Blessings
    mattr_accessor :blessings

    # Append the errors you want to ignore to the following array.
    #
    self.blessings = [
         "9ed37f41d6d123e805c3f00dbf6eb0a5", # The issue X is really a false positive because...
    ]
end
