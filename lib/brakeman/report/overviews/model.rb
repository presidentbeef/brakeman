class Brakeman::Report
  class Overview
    class Model < Brakeman::Report::Overview

      def report(html = false)
        @title = 'Model warnings'
        if @tracker.checks.model_warnings.any?
          warnings = []
          @tracker.checks.model_warnings.each do |warning|
            w = warning.to_row :model

            if html
              w["Confidence"] = Brakeman::Report::HTML_CONFIDENCE[w["Confidence"]]
              w["Message"] = with_context warning, w["Message"]
              w["Warning Type"] = with_link warning, w["Warning Type"]
            else
              w["Confidence"] = Brakeman::Report::TEXT_CONFIDENCE[w["Confidence"]]
              w["Message"] = text_message warning, w["Message"]
            end

            warnings << w
          end

          return nil if warnings.empty?
          stabilizer = 0
          warnings = warnings.sort_by{|row| stabilizer +=1; [row["Confidence"],row["Warning Type"], row["Model"], stabilizer]}

          locals = {:warnings => warnings}
          values = warnings.collect{|warning| [warning["Confidence"], warning["Model"], warning["Warning Type"], warning["Message"]] }
          render_array('model_warnings', ["Confidence", "Model", "Warning Type", "Message"], values, locals, html)
        else
          nil
        end
      end

    end
  end
end