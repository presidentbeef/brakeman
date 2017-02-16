## Testing

Run `bundle exec rake`

This runs Brakeman against full apps in the `apps` directory and checks the results against what is expected.

## Test Generation

Run `cd test && ruby to_test.rb apps/some_app > tests/some_app_test.rb` to generate a test suite with tests for each warning reported.
