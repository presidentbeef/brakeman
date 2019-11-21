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
end
