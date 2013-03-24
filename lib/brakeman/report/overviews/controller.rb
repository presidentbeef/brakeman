class Brakeman::Report
  class Overview
    class Controller < Brakeman::Report::Overview

      def report(html = false)
        controller_rows = []
        tracker.controllers.keys.map{|k| k.to_s}.sort.each do |name|
          name = name.to_sym
          c = tracker.controllers[name]

          if tracker.routes[:allow_all_actions] or tracker.routes[name] == :allow_all_actions
            routes = c[:public].keys.map{|e| e.to_s}.sort.join(", ")
          elsif tracker.routes[name].nil?
            #No routes defined for this controller.
            #This can happen when it is only a parent class
            #for other controllers, for example.
            routes = "[None]"

          else
            routes = (Set.new(c[:public].keys) & tracker.routes[name.to_sym]).
              to_a.
              map {|e| e.to_s}.
              sort.
              join(", ")
          end

          if routes == ""
            routes = "[None]"
          end

          controller_rows << { "Name" => name.to_s,
            "Parent" => c[:parent].to_s,
            "Includes" => c[:includes].join(", "),
            "Routes" => routes
          }
        end
        controller_rows = controller_rows.sort_by{|row| row['Name']}

        locals = {:controller_rows => controller_rows}
        values = controller_rows.collect{|row| [row['Name'], row['Parent'], row['Includes'], row['Routes']] }
        render_array('controller_overview', ['Name', 'Parent', 'Includes', 'Routes'], values, locals, html)
      end

    end
  end
end