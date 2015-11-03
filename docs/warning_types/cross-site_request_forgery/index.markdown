Cross-site request forgery is #5 on the [OWASP Top Ten](https://www.owasp.org/index.php/Top_10_2010-A5). CSRF allows an attacker to perform actions on a website as if they are an authenticated user.

This warning is raised when no call to `protect_from_forgery` is found in `ApplicationController`. This method prevents CSRF.

For Rails 4 applications, it is recommended that you use `protect_from_forgery :with => :exception`. This code is inserted into newly generated applications. The default is to `nil` out the session object, which has been a source of many CSRF bypasses due to session memoization.

See [the Ruby Security Guide](http://guides.rubyonrails.org/security.html#cross-site-request-forgery-csrf) for details.
