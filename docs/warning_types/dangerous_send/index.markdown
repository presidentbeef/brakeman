Using unfiltered user data to select a Class or Method to be dynamically sent is dangerous.

It is much safer to whitelist the desired target or method.

Unsafe use of method:

    method = params[:method]
    @result = User.send(method.to_sym)

Safe:

    method = params[:method] == 1 ? :method_a : :method_b
    @result = User.send(method, *args)

Unsafe use of target:

    table = params[:table]
    model = table.classify.constantize
    @result = model.send(:method)

Safe:

    target = params[:target] == 1 ? Account : User
    @result = target.send(:method, *args)

Including user data in the arguments passed to an Object#send is safe, as long as the method can properly handle potentially bad data.

Safe:
  
    args = params["args"] || []
    @result = User.send(:method, *args)
