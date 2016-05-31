class Thing < ApplicationRecord
  def self.self_and_descendants_for(id)
    where(<<-SQL, id: id)
      #{quoted_table_name}.#{quoted_primary_key} IN (
        WITH RECURSIVE descendant_tree(#{quoted_primary_key}, path) AS (
            SELECT #{quoted_primary_key}, ARRAY[#{quoted_primary_key}]
            FROM #{quoted_table_name}
            WHERE #{quoted_primary_key} = :id
          UNION ALL
            SELECT #{quoted_table_name}.#{quoted_primary_key}, descendant_tree.path || #{quoted_table_name}.#{quoted_primary_key}
            FROM descendant_tree
            JOIN #{quoted_table_name} ON #{quoted_table_name}.parent_id = descendant_tree.#{quoted_primary_key}
            WHERE NOT #{quoted_table_name}.#{quoted_primary_key} = ANY(descendant_tree.path)
        )
        SELECT #{quoted_primary_key}
        FROM descendant_tree
        ORDER BY path
      )
     SQL
  end
end
