class Brakeman::Report
  class Overview
    class General < Brakeman::Report::Overview

      def report(html = false)
        @title = 'Summary'
        warnings = @all_warnings.length

        if html
          locals = {
            :tracker => @tracker,
            :warnings => warnings,
            :warnings_summary => @warnings_summary,
            :number_of_templates => number_of_templates(@tracker),
            }

          Brakeman::Report::Renderer.new('overview', :locals => locals).render
        else
          Terminal::Table.new(:headings => ['Scanned/Reported', 'Total']) do |t|
            t.add_row ['Controllers', @tracker.controllers.length]
            t.add_row ['Models', @tracker.models.length - 1]
            t.add_row ['Templates', number_of_templates(@tracker)]
            t.add_row ['Errors', @tracker.errors.length]
            t.add_row ['Security Warnings', "#{warnings} (#{@warnings_summary[:high_confidence]})"]
          end
        end
      end

    end
  end
end