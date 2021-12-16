class User < ApplicationRecord
  STUFF = [
    DEFAULT_PASSWORD = "p@ssw3rd2"
  ]

  def self.scope_with_strip_heredoc(name)
    conditions = <<-SQL.strip_heredoc
      name = '#{name}'
    SQL

    where(conditions)
  end

  def self.render_user_input
    ERB.new(params)
  end

  def self.more_heredocs
    ActiveRecord::Base.connection.delete <<~SQL.chomp
      DELETE FROM #{table} WHERE updated_at < now() - interval '#{period}'
    SQL
  end

  def recent_stuff
    where("date > #{Date.today - 1}")
  end

  enum state: ["pending", "active", "archived"]

  def check_enum
    where("state = #{User.states["pending"]}")
  end

  enum "stuff_#{stuff}": [:things]

  def locale
    User.where("lower(slug_#{I18n.locale.to_s.split("-").first}) = :country_id", country_id: params[:new_country_id]).first
  end
end
