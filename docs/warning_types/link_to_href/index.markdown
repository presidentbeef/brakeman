Even though Rails will escape the link provided to `link_to`, values starting with `javascript:` or `data:` are unescaped and dangerous.

Brakeman will warn on if user values are used to provide the HREF value in `link_to` or if they are interpolated at the beginning of a string.

The `--url-safe-methods` option can be used to specify methods which make URLs safe. 

See [here](https://github.com/presidentbeef/brakeman/pull/45) for more details.
