User input passed into ruby templates that are evaluated is VERY dangerous, so this will always raise a warning. Brakeman looks foir calls of the form:

```ruby
  ERB.new(user_input).result
```
