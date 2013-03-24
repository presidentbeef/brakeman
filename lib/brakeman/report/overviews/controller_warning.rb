class Brakeman::Report
  class Overview
    class ControllerWarning < Brakeman::Report::Overview

      def report(html = false)
        @title = 'Controller Warnings'
        unless @tracker.checks.controller_warnings.empty?
          warnings = []
          @tracker.checks.controller_warnings.each do |warning|
            w = warning.to_row :controller

            if html
              w["Confidence"] = HTML_CONFIDENCE[w["Confidence"]]
              w["Message"] = with_context warning, w["Message"]
              w["Warning Type"] = with_link warning, w["Warning Type"]
            else
              w["Confidence"] = TEXT_CONFIDENCE[w["Confidence"]]
              w["Message"] = text_message warning, w["Message"]
            end

            warnings << w
          end

          return nil if warnings.empty?

          stabilizer = 0
          warnings = warnings.sort_by{|row| stabilizer +=1; [row["Confidence"], row["Warning Type"], row["Controller"], stabilizer]}

          locals = {:warnings => warnings}
          values = warnings.collect{|warning| [warning["Confidence"], warning["Controller"], warning["Warning Type"], warning["Message"]] }
          render_array('controller_warnings', ["Confidence", "Controller", "Warning Type", "Message"], values, locals, html)
        else
          nil
        end
      end

    end
  end
end