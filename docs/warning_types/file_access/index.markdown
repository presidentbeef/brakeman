Using user input when accessing files (local or remote) will raise a warning in Brakeman.

For example

    File.open("/tmp/#{cookie[:file]}")

will raise an error like

    Cookie value used in file name near line 4: File.open("/tmp/#{cookie[:file]}")

This type of vulnerability can be used to access arbitrary files on a server (including `/etc/passwd`.

If you are using `ActiveStorage`, use [sanitized](https://api.rubyonrails.org/classes/ActiveStorage/Filename.html#method-i-sanitized) URLs:

    ActiveStorage::Filename.new("foo/bar.jpg").sanitized # => "foo-bar.jpg"

Note: It replaces `/` with `-`.
