class Brakeman::Report::Sonar < Brakeman::Report::Base
  def generate_report
    warnings = all_warnings
    report_object = {
      rules: rules_json(warnings),
      issues: warnings.map { |warning| issue_json(warning) }
    }
    JSON.pretty_generate report_object
  end

  private

  def rules_json(warnings)
    warnings
      .each_with_object({}) do |w, unique_warnings|
        unique_warnings[[w.warning_code, w.confidence]] ||= w
      end
      .values
      .map do |w|
        {
          id: rule_id(w),
          name: w.warning_type.to_s,
          description: w.link,
          engineId: "Brakeman",
          cleanCodeAttribute: "TRUSTWORTHY",
          type: "VULNERABILITY",
          severity: rule_severity_for(w.confidence),
          impacts: [
            {
              softwareQuality: "SECURITY",
              severity: impact_severity_for(w.confidence)
            }
          ]
        }
      end
  end

  def issue_json(warning)
    {
      ruleId: rule_id(warning),
      effortMinutes: (4 - warning.confidence) * 15,
      primaryLocation: {
        message: warning.message,
        filePath: warning.file.relative,
        textRange: {
          startLine: warning.line || 1,
          endLine: warning.line || 1
        }
      }
    }
  end

  def rule_id(warning)
    "BRAKEMAN_#{warning.warning_code}_#{rule_severity_for(warning.confidence)}"
  end

  def rule_severity_for(confidence)
    case confidence
    when 0 then "CRITICAL"
    when 1 then "MAJOR"
    else "MINOR"
    end
  end

  def impact_severity_for(confidence)
    case confidence
    when 0 then "HIGH"
    when 1 then "MEDIUM"
    else "LOW"
    end
  end
end
