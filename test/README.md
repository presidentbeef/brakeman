## Testing

Run `rake` or if you want to avoid bundler `cd test && ruby test.rb`.

This runs Brakeman against full apps in the `apps` directory and checks the results against what is expected.

## Test Generation

Run `cd test && ruby to_test.rb apps/some_app > tests/test_some_app.rb` to generate a test suite with tests for each warning reported.
