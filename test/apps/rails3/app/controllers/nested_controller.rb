class Whatever
  module Wherever
    class NestedController < ApplicationController
      def just_testing
        #that this does not cause errors
      end
    end
  end
end
