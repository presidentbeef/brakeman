class Brakeman::CheckHosts < Brakeman::BaseCheck
  Brakeman::Checks.add_optional self

  @description = "Check that hosts setting is not empty in development"

  def run_check
    return if tracker.config.rails.empty? or tracker.config.rails_version.nil?
    return if tracker.config.rails_version < "6"

    hosts = tracker.config.rails[:hosts]

    if hosts.nil? || hosts.empty?
      line = if sexp? hosts
               hosts.line
             else
               1
             end

      warn :warning_type => "DNS rebinding",
        :warning_code => :hosts_empty,
        :message => msg("The application does not guard against DNS rebinding: ", msg_code("config.hosts"), " is empty"),
        :confidence => :high,
        :file => "config/environments/development.rb",
        :line => line
    end
  end
end
