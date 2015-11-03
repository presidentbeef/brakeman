Mass assignment is a feature of Rails which allows an application to create a record from the values of a hash.

Example:

    User.new(params[:user])

Unfortunately, if there is a user field called `admin` which controls administrator access, now any user can make themselves an administrator.

`attr_accessible` and `attr_protected` can be used to limit mass assignment. However, Brakeman will warn unless `attr_accessible` is used, or mass assignment is completely disabled. 

There are two different mass assignment warnings which can arise. The first is when mass assignment actually occurs, such as the example above. This results in a warning like

    Unprotected mass assignment near line 61: User.new(params[:user])

The other warning is raised whenever a model is found which does not use `attr_accessible`. This produces generic warnings like

    Mass assignment is not restricted using attr_accessible

with a list of affected models.

In Rails 3.1 and newer, mass assignment can easily be disabled:

    config.active_record.whitelist_attributes = true

Unfortunately, it can also easily be bypassed:

    User.new(params[:user], :without_protection => true)

Brakeman will warn on uses of `without_protection`.
