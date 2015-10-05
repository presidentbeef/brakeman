Cross site scripting (or XSS) is #2 on the 2010 [OWASP Top Ten](https://www.owasp.org/index.php/Top_10_2010-A2) web security risks and it pops up nearly everywhere.

XSS occurs when a user-manipulatable value is displayed on a web page without escaping it, allowing someone to inject Javascript or HTML into the page.

In Rails 2.x, values need to be explicitly escaped (e.g., by using the `h` method). In Rails 3.x, auto-escaping in views is enabled by default. However, one can still use the `raw` method to output a value directly.

See [the Ruby Security Guide](http://guides.rubyonrails.org/security.html#cross-site-scripting-xss) for more details.

### Query Parameters and Cookies

Rails 2.x example in ERB:

    <%= params[:query] %>

Brakeman looks for several situations that can allow XSS. The simplest is like the example above: a value from the `params` or `cookies` is being directly output to a view. In such cases, it will issue a warning like:

    Unescaped parameter value near line 3: params[:query]

By default, Brakeman will also warn when a parameter or cookie value is used as an argument to a method, the result of which is output unescaped to a view.

For example:

    <%= some_method(cookie[:name]) %>

This raises a warning like:

    Unescaped cookie value near line 5: some_method(cookies[:oreo])

However, the confidence level for this warning will be weak, because it is not directly outputting the cookie value.

Some methods are known to Brakeman to either be dangerous (`link_to` is one) or safe (`escape_once`). Users can specify safe methods using the `--safe-methods` option. Alternatively, Brakeman can be set to _only_ warn when values are used directly with the `--report-direct` option.

### Model Attributes

Because (many) models come from database values, Brakeman mistrusts them by default.

For example, if `@user` is an instance of a model set in an action like

    def set_user
      @user = User.first
    end

and there is a view with

    <%= @user.name %>

Brakeman will raise a warning like

    Unescaped model attribute near line 3: User.first.name

If you trust all your data (although you probably shouldn't), this can be disabled with `--ignore-model-output`.
