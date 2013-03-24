class Brakeman::Report
  class Overview
    class TemplateWarning < Brakeman::Report::Overview

      def report(html = false)
        if @tracker.checks.template_warnings.any?
          warnings = []
          @tracker.checks.template_warnings.each do |warning|
            w = warning.to_row :template

            if html
              w["Confidence"] = HTML_CONFIDENCE[w["Confidence"]]
              w["Message"] = with_context warning, w["Message"]
              w["Warning Type"] = with_link warning, w["Warning Type"]
              w["Called From"] = warning.called_from
              w["Template Name"] = warning.template[:name]
            else
              w["Confidence"] = TEXT_CONFIDENCE[w["Confidence"]]
              w["Message"] = text_message warning, w["Message"]
            end

            warnings << w
          end

          return nil if warnings.empty?

          stabilizer = 0
          warnings = warnings.sort_by{|row| stabilizer += 1; [row["Confidence"], row["Warning Type"], row["Template"], stabilizer]}

          locals = {:warnings => warnings}
          values = warnings.collect{|warning| [warning["Confidence"], warning["Template"], warning["Warning Type"], warning["Message"]] }
          render_array('view_warnings', ["Confidence", "Template", "Warning Type", "Message"], values, locals, html)
        else
          nil
        end
      end

    end
  end
end