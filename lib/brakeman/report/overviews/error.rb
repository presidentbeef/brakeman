class Brakeman::Report
  class Overview
    class Error < Brakeman::Report::Overview

      def report(html = false)
        values = @tracker.errors.collect{|error| [error[:error], error[:backtrace][0]]}
        render_array('error_overview', ['Error', 'Location'], values, {:tracker => @tracker}, html)
      end

    end
  end
end