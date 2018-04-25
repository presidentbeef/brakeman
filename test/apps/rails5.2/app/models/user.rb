class User < ActiveRecord::Base
  def not_something thing
    where.not("blah == #{thing}")
  end
  SUBQUERY_TABLE_ALIAS = "my_table_alias".freeze

  # This is used inside a larger query by using `inner_query.to_sql`
  def inner_query
    self.class.
      select("#{SUBQUERY_TABLE_ALIAS}.*").
      from("#{table_name} AS #{SUBQUERY_TABLE_ALIAS}")
  end
end
