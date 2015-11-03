The general default routes warning means there is a call to

    #Rails 2.x
    map.connect ":controller/:action/:id"

or

    Rails 3.x
    match ':controller(/:action(/:id(.:format)))'

in `config/routes.rb`. This allows any public method on any controller to be called as an action.

If this warning is reported for a particular controller, it means there is a route to that controller containing `:action`.

Default routes can be dangerous if methods are made public which are not intended to be used as URLs or actions.
