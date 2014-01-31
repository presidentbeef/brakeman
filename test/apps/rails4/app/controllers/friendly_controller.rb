class FriendlyController
  some_helper_thing do
    @user = User.current_user
  end

  def find
    @user = User.friendly.find(params[:id])
    redirect_to @user
  end

  def some_user_thing
    redirect_to @user.url
  end

  def try_and_send
    User.stuff.try(:where, params[:query])
    User.send(:from, params[:table]).all
  end

  def mass_assign_user
    # Should warn about permit!
    x = params.permit!
    @user = User.new(x)
  end

  def mass_assign_protected_model
    # Warns with medium confidence because Account uses attr_accessible
    params.permit!
    Account.new(params)
  end

  def permit_without_usage
    # Warns with medium confidence because there is no mass assignment
    params.permit!
  end

  def permit_after_usage
    # Warns with medium confidence because permit! is called after mass assignment
    User.new(params)
    params.permit!
  end

  def sql_with_exec
    User.connection.select_values <<-SQL
      SELECT id FROM collection_items
        WHERE id > #{last_collection_item.id}
          AND collection_id IN (#{destinations.map { |d| d.id}.join(',')})"
    SQL

    Account.connection.select_rows("select thing.id, count(*) from things_stuff toc
                                     join things dotoc on (toc.id=dotoc.toc_id)
                                     join things do on (dotoc.data_object_id=do.id)
                                     join thing_entries dohe on do.id = dohe.data_object_id
                                     where do.published=#{params[:published]} and dohe.visibility_id=#{something.id} group by toc.id")
  end
end
