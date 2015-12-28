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

  def redirect_to_some_places
    if something
      redirect_to params.merge(:host => "example.com") # Should not warn
    elsif something_else
      redirect_to params.merge(:host => User.canonical_url) # Should not warn
    else
      redirect_to params.merge(:host => params[:host]) # Should warn
    end
  end

  def select_some_stuff
    User.select(:name, params[:x])
  end

  def send_some_stuff
    blah.send(params[:x]).to_json
  end

  private def private_some_stuff
    eval params[:what_is_this_java?]
  end

  def where_hashes
    User.where('stuff' => params[:stuff]) # no warning
    User.where(params[:key] => params[:stuff]) # warn
  end

  def whitelistit
    whitelist = ["Post", "Comments"]
    whitelisted_class_name = whitelist.detect {|k| k == params[:a]}
    if whitelisted_class_name.nil?
      raise "Nope!"
    else
      whitelisted_class_name.constantize
    end
  end
end
