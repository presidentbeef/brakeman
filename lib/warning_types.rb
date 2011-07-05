require "active_support/core_ext"

#a simple container for the warning types descriptions
module WarningTypes
    mattr_accessor :description

    self.description = {
"Cross Site Scripting" => <<-HTML
Cross site scripting warnings are raised when a parameter or model attribute is output through a view without being escaped.

See http://guides.rubyonrails.org/security.html#cross-site-scripting-xss for details.
HTML
    }
    self.description["SQL Injection"] =<<-HTML

String interpolation or concatenation has been detected in an SQL query. Use parameterized queries instead.

See http://guides.rubyonrails.org/security.html#sql-injection for details.

HTML
    self.description["Command Injection"] =<<-HTML

Request parameters or string interpolation has been detected in a `system` call. This can lead to someone executing arbitrary commands. Use the safe form of `system` instead, which will pass in arguments safely.

See http://guides.rubyonrails.org/security.html#command-line-injection for details.

HTML
    self.description["Mass Assignment"] =<<-HTML

Mass assignment is a method for initializing models. If the attributes which are set is not restricted, someone may set the attributes to any value they wish.

Mass assignment can be disabled globally.

Please see http://railspikes.com/2008/9/22/is-your-rails-application-safe-from-mass-assignment for more details.

HTML
    self.description["Attribute Restriction"] =<<-HTML

This warning comes up if a model does not limit what attributes can be set through mass assignment.

In particular, this check looks for `attr_accessible` inside model definitions. If it is not found, this warning will be issued.

Note that disabling mass assignment globally will suppress these warnings.

HTML
    self.description["Cross-Site Request Forgery"] =<<-HTML

No call to `protect_from_forgery` was found in `ApplicationController`. This method prevents CSRF.

See http://guides.rubyonrails.org/security.html#cross-site-request-forgery-csrf for details.

HTML
    self.description["Redirect"] =<<-HTML

Redirects which rely on user-supplied values can be used to "spoof" websites or hide malicious links in otherwise harmless-looking URLs. They can also allow access to restricted areas of a site if the destination is not validated.

This warning is shown when request parameters are used inside a call to `redirect_to`.

See http://www.owasp.org/index.php/Top_10_2010-A10 for more information.

HTML
    self.description["Default Routes"] =<<-HTML

The general default routes warning means there is a call to `map.connect ":controller/:action/:id"` in config/routes.rb. This allows any public method on any controller to be called as an action.

If this warning is reported for a particular controller, it means there is a route to that controller containing `:action`.

Default routes can be dangerous if methods are made public which are not intended to be used as URLs or actions.

HTML
    self.description["Format Validation"] =<<-HTML

Calls to `validates_format_of ..., :with => //` which do not use `\A` and `\z` as anchors will cause this warning. Using `^` and `$` is not sufficient, as `$` will only match up to a new line. This allows an attacker to put whatever malicious input they would like after a new line character.

See http://guides.rubyonrails.org/security.html#regular-expressions for details.

HTML
    self.description["Dynamic Render Path"] =<<-HTML

When a call to `render` uses a dynamically generated path, template name, file name, or action, there is the possibility that a user can access templates that should be restricted. The issue may be worse if those templates execute code or modify the database.

This warning is shown whenever the path to be rendered is not a static string or symbol.
HTML

end
