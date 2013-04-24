class Whatever
  module Wherever
    class NestedController < ApplicationController
      def so_nested
        @bad_thing = params[:x]
      end
    end
  end
end
