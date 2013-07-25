#Generated tab-separated output suitable for the Jenkins Brakeman Plugin:
#https://github.com/presidentbeef/brakeman-jenkins-plugin
class Brakeman::Report::Tabs < Brakeman::Report::Base
  def generate_report
    [[:generic_warnings, "General"], [:controller_warnings, "Controller"],
      [:model_warnings, "Model"], [:template_warnings, "Template"]].map do |meth, category|

      self.send(meth).map do |w|
        line = w.line || 0
        w.warning_type.gsub!(/[^\w\s]/, ' ')
        "#{warning_file(w, :absolute)}\t#{line}\t#{w.warning_type}\t#{category}\t#{w.format_message}\t#{TEXT_CONFIDENCE[w.confidence]}"
      end.join "\n"

    end.join "\n"

  end
end
