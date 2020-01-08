class ShellStuff
  def initialize(one, two)
    @one = Shellwords.shellescape(one)
    @two = Shellwords.escape(two)
  end

  def run(ip)
    ip = Shellwords.shellescape(ip)
    `dig +short -x #{ip} @#{@one} -p #{@two}`
    `command #{Shellwords.escape(@one)}`
    `command #{Shellwords.join(@two)}`
    `command #{Shellwords.shelljoin(@two)}`
    `command #{@one.shellescape}`
    `command #{@two.shelljoin}`
  end

  def backticks_target(path)
    `echo #{path}`.chomp
  end

  def process_pid
    # should not warn
    `something #{Process.pid}`
  end

  def nested_system_interp
    filename = Shellwords.escape("#{file_prefix}.txt")
    system "echo #{filename}"
  end

  def system_array_join
    command = ["ruby", method_that_returns_user_input, "--some-flag"].join(" ")
    system(command)
  end

  def system_as_target
    !system("echo #{foo}")
  end

  def interpolated_conditional_safe
    `echo #{"foo" if foo} bar`
  end

  def interpolated_ternary_safe
    `echo #{foo ? "bar" : "baz"}`
  end

  def interpolated_conditional_dangerous
    `echo #{bar if foo} baz`
  end

  def interpolated_ternary_dangerous
    `echo #{foo ? "bar" : bar} baz`
  end

  COMMANDS = { foo: "echo", bar: "cat" }
  MORE_COMMANDS = { foo: "touch" }

  def safe(arg)
    command = if Date.today.tuesday? # Some condition.
                COMMANDS[arg]
              else
                MORE_COMMANDS[arg]
              end

    `#{command} file1.txt`
  end

  EXPRESSIONS = ["users.email", "concat_ws(' ', users.first_name, users.last_name)"]

  def perform_commands
    EXPRESSIONS.each { |exp| `echo #{exp}` }
  end

  def scopes(base_scope)
    EXPRESSIONS.map { |exp| base_scope.where("#{exp} ILIKE '%foo%'") }
  end

  def shell_escape_model
    a = User.new
    z = Shellwords.escape(a.z)
    result, status = Open3.capture2e("ls",
                                     z)  # Should not warn

    `ls #{z}` # Also should not warn
  end

  def file_constant_use
    # __FILE__ should not change based on absolute path
    `cp #{__FILE__} #{somewhere_else}`
  end

  def interpolated_in_percent_W
    # Should not warn
    system(*%W(foo bar #{value}))
  end

  def completely_external
    system(foo) # We assume this is safe and do not warn.
  end

  def string_concatenation
    system("echo " + foo)
  end

  def escaped_string_concatenation
    system("echo " + Shellwords.escape(foo))
  end

  def safe_string_concatenation
    system("echo " + "foo")
  end

  def dash_c_dangerous_concatenation
    system("bash", "-c", "echo " + foo)
  end

  def dash_c_safe_concatenation
    system("bash", "-c", "echo " + Shellwords.escape(foo))
  end

  def popen_dash_c
    IO.popen(["bash", "-c", params[:foo]]) {}
  end

  def popen_concatenation
    IO.popen("ls " + foo) do |ls_io|
      ls_io.read
    end
  end
end
