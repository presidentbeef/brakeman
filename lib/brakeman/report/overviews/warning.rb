class Brakeman::Report
  class Overview
    class Warning < Brakeman::Report::Overview

      def report(html = false)
        @title = 'Warnings'
        types = @warnings_summary.keys
        types.delete :high_confidence
        values = types.sort.collect{|warning_type| [warning_type, @warnings_summary[warning_type]] }
        locals = {:types => types, :warnings_summary => @warnings_summary}

        render_array('warning_overview', ['Warning Type', 'Total'], values, locals, html)
      end

    end
  end
end