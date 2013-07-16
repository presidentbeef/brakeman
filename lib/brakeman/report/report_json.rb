Brakeman.load_dependency 'multi_json'
require 'brakeman/report/initializers/multi_json'

class Brakeman::Report::JSON < Brakeman::Report::Base
  def generate_report
    errors = tracker.errors.map{|e| { :error => e[:error], :location => e[:backtrace][0] }}
    app_path = tracker.options[:app_path]

    warnings = convert_to_hashes all_warnings

    ignored = convert_to_hashes ignored_warnings

    scan_info = {
      :app_path => File.expand_path(tracker.options[:app_path]),
      :rails_version => rails_version,
      :security_warnings => all_warnings.length,
      :start_time => tracker.start_time.to_s,
      :end_time => tracker.end_time.to_s,
      :duration => tracker.duration,
      :checks_performed => checks.checks_run.sort,
      :number_of_controllers => tracker.controllers.length,
      # ignore the "fake" model
      :number_of_models => tracker.models.length - 1,
      :number_of_templates => number_of_templates(@tracker),
      :ruby_version => RUBY_VERSION,
      :brakeman_version => Brakeman::Version
    }

    report_info = {
      :scan_info => scan_info,
      :warnings => warnings,
      :ignored_warnings => ignored,
      :errors => errors
    }

    MultiJson.dump(report_info, :pretty => true)
  end

  def convert_to_hashes warnings
    warnings.map do |w|
      hash = w.to_hash
      hash[:file] = warning_file w
      hash
    end.sort_by { |w| w[:file] }
  end
end
