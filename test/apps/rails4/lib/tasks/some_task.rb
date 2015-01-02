class SomeTask
  def some_task
    # Should not warn because we are ignoring tasks
    `#{x}`
  end
end
