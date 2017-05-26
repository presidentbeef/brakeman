Injection is #1 on the 2013 [OWASP Top Ten](https://www.owasp.org/index.php/Top_10_2013-A1-Injection) web security risks. SQL injection is when a user is able to manipulate a value which is used unsafely inside a SQL query. This can lead to data leaks, data loss, elevation of privilege, and other unpleasant outcomes.

Brakeman focuses on ActiveRecord methods dealing with building SQL statements.

A basic (Rails 2.x) example looks like this:

    User.first(:conditions => "username = '#{params[:username]}'")

Brakeman would produce a warning like this:

    Possible SQL injection near line 30: User.first(:conditions => ("username = '#{params[:username]}'")) 

The safe way to do this query is to use a parameterized query:

    User.first(:conditions => ["username = ?", params[:username]])

Brakeman also understands the new Rails 3.x way of doing things (and local variables and concatenation):

    username = params[:user][:name].downcase
    password = params[:user][:password]

    User.first.where("username = '" + username + "' AND password = '" + password + "'")

This results in this kind of warning:

    Possible SQL injection near line 37:
    User.first.where((((("username = '" + params[:user][:name].downcase) + "' AND password = '") + params[:user][:password]) + "'"))

See [the Ruby Security Guide](http://guides.rubyonrails.org/security.html#sql-injection) for more information and [Rails-SQLi.org](http://rails-sqli.org) for many examples of SQL injection in Rails.
