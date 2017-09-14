## Testing

Run `bundle` then `rake` or if you want to avoid bundler `ruby test/test.rb`.

This runs Brakeman against full apps in the `apps` directory and checks the results against what is expected.

## Test Generation

Run `cd test && ruby to_test.rb apps/some_app > tests/some_app.rb` to generate a test suite with tests for each warning reported.

## Single File

Run `ruby test/tests/some_file.rb` to run a single file of tests.

## Single Test

Ruby `ruby test/test.rb --name test_something` to run a single test.
