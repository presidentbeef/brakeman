Unvalidated redirects and forwards are #10 on the [OWASP Top Ten](https://www.owasp.org/index.php/Top_10_2010-A10).

Redirects which rely on user-supplied values can be used to "spoof" websites or hide malicious links in otherwise harmless-looking URLs. They can also allow access to restricted areas of a site if the destination is not validated.

Brakeman will raise warnings whenever `redirect_to` appears to be used with a user-supplied value that may allow them to change the `:host` option.

For example,

    redirect_to params.merge(:action => :home)

will create a warning like

    Possible unprotected redirect near line 46: redirect_to(params)

This is because `params` could contain `:host => 'evilsite.com'` which would redirect away from your site and to a malicious site.

If the first argument to `redirect_to` is a hash, then adding `:only_path => true` will limit the redirect to the current host. Another option is to specify the host explicitly.

    redirect_to params.merge(:only_path => true)

    redirect_to params.merge(:host => 'myhost.com')

If the first argument is a string, then it is possible to parse the string and extract the path:

    redirect_to URI.parse(some_url).path 

If the URL does not contain a protocol (e.g., `http://`), then you will probably get unexpected results, as `redirect_to` will prepend the current host name and a protocol.
