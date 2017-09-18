Brakeman warns about several different session-related issues.

### HTTP Only

It is recommended that session cookies be set to `http-only`. This helps prevent stealing of cookies via cross-site scripting.

### Secret Length

Brakeman will warn if the key length for the session cookies is less than 30 characters.

### Session Secret in Version Control

Brakeman will warn if the `config/initializers/secret_token.rb` is included in the version control. It is recommended to exclude `secret_token.rb` from version control and include it in `.gitignore`.
