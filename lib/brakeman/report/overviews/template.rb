class Brakeman::Report
  class Overview
    class Template < Brakeman::Report::Overview

      def report(html = false)
        out_processor = Brakeman::OutputProcessor.new
        template_rows = {}
        @tracker.templates.each do |name, template|
          unless template[:outputs].empty?
            template[:outputs].each do |out|
              out = out_processor.format out
              out = CGI.escapeHTML(out) if html
              template_rows[name] ||= []
              template_rows[name] << out.gsub("\n", ";").gsub(/\s+/, " ")
            end
          end
        end

        template_rows = template_rows.sort_by{|name, value| name.to_s}

        if html
          Brakeman::Report::Renderer.new('template_overview', :locals => {:template_rows => template_rows}).render
        else
          output = ''
          template_rows.each do |template|
            output << template.first.to_s << "\n\n"
            table = Terminal::Table.new(:headings => ['Output']) do |t|
              # template[1] is an array of calls
              template[1].each do |v|
                t.add_row [v]
              end
            end

            output << table.to_s << "\n\n"
          end

          output
        end
      end

    end
  end
end