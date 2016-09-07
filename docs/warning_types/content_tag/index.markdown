Cross-site scripting (or XSS) is #2 on the 2010 [OWASP Top Ten](https://www.owasp.org/index.php/Top_10_2010-A2) web security risks and it pops up nearly everywhere. XSS occurs when a user-manipulatable value is displayed on a web page without escaping it, allowing someone to inject Javascript or HTML into the page.

[content\_tag](http://apidock.com/rails/ActionView/Helpers/TagHelper/content_tag) is a view helper which generates an HTML tag with some content:

    >> content_tag :p, "Hi!"
    => "<p>Hi!</p>"

In Rails 2, this content is unescaped (although attribute values are escaped):

    >> content_tag :p, "<script>alert(1)</script>"
    => "<p><script>alert(1)</script></p>"

In Rails 3, the content is escaped. However, only the *content* and the tag attribute *values* are escaped. The tag and attribute names are never escaped in Rails 2 or 3.

This is more dangerous than a typical method call because `content_tag` marks its output as "HTML safe", meaning the `rails_xss` plugin and Rails 3 auto-escaping will not escape its output. Due to this, `content_tag` should be used carefully if user input is provided as an argument.

Note that while `content_tag` does have an `escape` parameter, this only applies to tag attribute *values* and is true by default.
