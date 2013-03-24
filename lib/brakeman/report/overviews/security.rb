class Brakeman::Report
  class Overview
    class Security < Brakeman::Report::Overview

      def report(html = false)
        warning_messages = []
        @tracker.checks.warnings.each do |warning|
          w = warning.to_row

          if html
            w["Confidence"] = HTML_CONFIDENCE[w["Confidence"]]
            w["Message"] = with_context warning, w["Message"]
            w["Warning Type"] = with_link warning, w["Warning Type"]
          else
            w["Confidence"] = TEXT_CONFIDENCE[w["Confidence"]]
            w["Message"] = text_message warning, w["Message"]
          end

          warning_messages << w
        end

        stabilizer = 0
        warning_messages = warning_messages.sort_by{|row| stabilizer += 1; [row['Confidence'], row['Warning Type'], row['Class'], stabilizer]}

        locals = {:warning_messages => warning_messages}
        values = warning_messages.collect{|row| [row["Confidence"], row["Class"], row["Method"], row["Warning Type"], row["Message"]] }
        render_array('security_warnings', ["Confidence", "Class", "Method", "Warning Type", "Message"], values, locals, html)
      end

    end
  end
end