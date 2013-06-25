# Generates a hash table for use in Brakeman tests
class Brakeman::Report::Hash < Brakeman::Report::Base
  def generate_report
    report = { :errors => tracker.errors,
               :controllers => tracker.controllers,
               :models => tracker.models,
               :templates => tracker.templates
              }

    [:warnings, :controller_warnings, :model_warnings, :template_warnings].each do |meth|
      report[meth] = @checks.send(meth)
      report[meth].each do |w|
        w.message = w.format_message
        w.context = context_for(@app_tree, w).join("\n")
      end
    end

    report[:config] = tracker.config

    report
  end
end
