require 'set'
require 'pathname'

#This is a mixin containing utility methods.
module Brakeman::Util

  QUERY_PARAMETERS = Sexp.new(:call, Sexp.new(:call, nil, :request), :query_parameters)

  PATH_PARAMETERS = Sexp.new(:call, Sexp.new(:call, nil, :request), :path_parameters)

  REQUEST_PARAMETERS = Sexp.new(:call, Sexp.new(:call, nil, :request), :request_parameters)

  REQUEST_PARAMS = Sexp.new(:call, Sexp.new(:call, nil, :request), :parameters)

  REQUEST_ENV = Sexp.new(:call, Sexp.new(:call, nil, :request), :env)

  PARAMETERS = Sexp.new(:call, nil, :params)

  COOKIES = Sexp.new(:call, nil, :cookies)

  REQUEST_COOKIES = s(:call, s(:call, nil, :request), :cookies)

  SESSION = Sexp.new(:call, nil, :session)

  ALL_PARAMETERS = Set[PARAMETERS, QUERY_PARAMETERS, PATH_PARAMETERS, REQUEST_PARAMETERS, REQUEST_PARAMS]

  ALL_COOKIES = Set[COOKIES, REQUEST_COOKIES]

  #Convert a string from "something_like_this" to "SomethingLikeThis"
  #
  #Taken from ActiveSupport.
  def camelize lower_case_and_underscored_word
    lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
  end

  #Convert a string from "Something::LikeThis" to "something/like_this"
  #
  #Taken from ActiveSupport.
  def underscore camel_cased_word
    camel_cased_word.to_s.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end

  # stupid simple, used to delegate to ActiveSupport
  def pluralize word
    word + "s"
  end

  #Returns a class name as a Symbol.
  #If class name cannot be determined, returns _exp_.
  def class_name exp
    case exp
    when Sexp
      case exp.node_type
      when :const
        exp.value
      when :lvar
        exp.value.to_sym
      when :colon2
        "#{class_name(exp.lhs)}::#{exp.rhs}".to_sym
      when :colon3
        "::#{exp.value}".to_sym
      when :self
        @current_class || @current_module || nil
      else
        exp
      end
    when Symbol
      exp
    when nil
      nil
    else
      exp
    end
  end

  #Takes an Sexp like
  # (:hash, (:lit, :key), (:str, "value"))
  #and yields the key and value pairs to the given block.
  #
  #For example:
  #
  # h = Sexp.new(:hash, (:lit, :name), (:str, "bob"), (:lit, :name), (:str, "jane"))
  # names = []
  # hash_iterate(h) do |key, value|
  #   if symbol? key and key[1] == :name
  #     names << value[1]
  #   end
  # end
  # names #["bob"]
  def hash_iterate hash
    1.step(hash.length - 1, 2) do |i|
      yield hash[i], hash[i + 1]
    end
  end

  #Insert value into Hash Sexp
  def hash_insert hash, key, value
    index = 1
    hash_iterate hash.dup do |k,v|
      if k == key
        hash[index + 1] = value
        return hash
      end
      index += 2
    end

    hash << key << value

    hash
  end

  #Get value from hash using key.
  #
  #If _key_ is a Symbol, it will be converted to a Sexp(:lit, key).
  def hash_access hash, key
    if key.is_a? Symbol
      key = Sexp.new(:lit, key)
    end

    if index = hash.find_index(key) and index > 0
      return hash[index + 1]
    end

    nil
  end

  #These are never modified
  PARAMS_SEXP = Sexp.new(:params)
  SESSION_SEXP = Sexp.new(:session)
  COOKIES_SEXP = Sexp.new(:cookies)

  #Adds params, session, and cookies to environment
  #so they can be replaced by their respective Sexps.
  def set_env_defaults
    @env[PARAMETERS] = PARAMS_SEXP
    @env[SESSION] = SESSION_SEXP
    @env[COOKIES] = COOKIES_SEXP
  end

  #Check if _exp_ represents a hash: s(:hash, {...})
  #This also includes pseudo hashes params, session, and cookies.
  def hash? exp
    exp.is_a? Sexp and (exp.node_type == :hash or
                        exp.node_type == :params or
                        exp.node_type == :session or
                        exp.node_type == :cookies)
  end

  #Check if _exp_ represents an array: s(:array, [...])
  def array? exp
    exp.is_a? Sexp and exp.node_type == :array
  end

  #Check if _exp_ represents a String: s(:str, "...")
  def string? exp
    exp.is_a? Sexp and exp.node_type == :str
  end

  def string_interp? exp
    exp.is_a? Sexp and exp.node_type == :dstr
  end

  #Check if _exp_ represents a Symbol: s(:lit, :...)
  def symbol? exp
    exp.is_a? Sexp and exp.node_type == :lit and exp[1].is_a? Symbol
  end

  #Check if _exp_ represents a method call: s(:call, ...)
  def call? exp
    exp.is_a? Sexp and
      (exp.node_type == :call or exp.node_type == :safe_call)
  end

  #Check if _exp_ represents a Regexp: s(:lit, /.../)
  def regexp? exp
    exp.is_a? Sexp and exp.node_type == :lit and exp[1].is_a? Regexp
  end

  #Check if _exp_ represents an Integer: s(:lit, ...)
  def integer? exp
    exp.is_a? Sexp and exp.node_type == :lit and exp[1].is_a? Integer
  end

  #Check if _exp_ represents a number: s(:lit, ...)
  def number? exp
    exp.is_a? Sexp and exp.node_type == :lit and exp[1].is_a? Numeric
  end

  #Check if _exp_ represents a result: s(:result, ...)
  def result? exp
    exp.is_a? Sexp and exp.node_type == :result
  end

  #Check if _exp_ represents a :true, :lit, or :string node
  def true? exp
    exp.is_a? Sexp and (exp.node_type == :true or
                        exp.node_type == :lit or
                        exp.node_type == :string)
  end

  #Check if _exp_ represents a :false or :nil node
  def false? exp
    exp.is_a? Sexp and (exp.node_type == :false or
                        exp.node_type == :nil)
  end

  #Check if _exp_ represents a block of code
  def block? exp
    exp.is_a? Sexp and (exp.node_type == :block or
                        exp.node_type == :rlist)
  end

  #Check if _exp_ is a params hash
  def params? exp
    if exp.is_a? Sexp
      return true if exp.node_type == :params or ALL_PARAMETERS.include? exp

      if call? exp
        if params? exp[1]
          return true
        elsif exp[2] == :[]
          return params? exp[1]
        end
      end
    end

    false
  end

  def cookies? exp
    if exp.is_a? Sexp
      return true if exp.node_type == :cookies or ALL_COOKIES.include? exp

      if call? exp
        if cookies? exp[1]
          return true
        elsif exp[2] == :[]
          return cookies? exp[1]
        end
      end
    end

    false
  end

  def request_env? exp
    call? exp and (exp == REQUEST_ENV or exp[1] == REQUEST_ENV)
  end

  #Check if exp is params, cookies, or request_env
  def request_value? exp
    params? exp or
    cookies? exp or
    request_env? exp
  end

  def constant? exp
    node_type? exp, :const, :colon2, :colon3
  end

  #Check if _exp_ is a Sexp.
  def sexp? exp
    exp.is_a? Sexp
  end

  #Check if _exp_ is a Sexp and the node type matches one of the given types.
  def node_type? exp, *types
    exp.is_a? Sexp and types.include? exp.node_type
  end

  #Returns true if the given _exp_ contains a :class node.
  #
  #Useful for checking if a module is just a module or if it is a namespace.
  def contains_class? exp
    todo = [exp]

    until todo.empty?
      current = todo.shift

      if node_type? current, :class
        return true
      elsif sexp? current
        todo = current[1..-1].concat todo
      end
    end

    false
  end

  def make_call target, method, *args
    call = Sexp.new(:call, target, method)

    if args.empty? or args.first.empty?
      #nothing to do
    elsif node_type? args.first, :arglist
      call.concat args.first[1..-1]
    elsif args.first.node_type.is_a? Sexp #just a list of args
      call.concat args.first
    else
      call.concat args
    end

    call
  end

  def rails_version
    @tracker.config.rails_version
  end

  #Return file name related to given warning. Uses +warning.file+ if it exists
  def file_for warning, tracker = nil
    if tracker.nil?
      tracker = @tracker || self.tracker
    end

    if warning.file
      File.expand_path warning.file, tracker.app_path
    elsif warning.template and warning.template.file
      warning.template.file
    else
      case warning.warning_set
      when :controller
        file_by_name warning.controller, :controller, tracker
      when :template
        file_by_name warning.template.name, :template, tracker
      when :model
        file_by_name warning.model, :model, tracker
      when :warning
        file_by_name warning.class, nil, tracker
      else
        nil
      end
    end
  end

  #Attempt to determine path to context file based on the reported name
  #in the warning.
  #
  #For example,
  #
  #  file_by_name FileController #=> "/rails/root/app/controllers/file_controller.rb
  def file_by_name name, type, tracker = nil
    return nil unless name
    string_name = name.to_s
    name = name.to_sym

    unless type
      if string_name =~ /Controller$/
        type = :controller
      elsif camelize(string_name) == string_name # This is not always true
        type = :model
      else
        type = :template
      end
    end

    path = tracker.app_path

    case type
    when :controller
      if tracker.controllers[name]
        path = tracker.controllers[name].file
      else
        path += "/app/controllers/#{underscore(string_name)}.rb"
      end
    when :model
      if tracker.models[name]
        path = tracker.models[name].file
      else
        path += "/app/models/#{underscore(string_name)}.rb"
      end
    when :template
      if tracker.templates[name] and tracker.templates[name].file
        path = tracker.templates[name].file
      elsif string_name.include? " "
        name = string_name.split[0].to_sym
        path = file_for tracker, name, :template
      else
        path = nil
      end
    end

    path
  end

  #Return array of lines surrounding the warning location from the original
  #file.
  def context_for app_tree, warning, tracker = nil
    file = file_for warning, tracker
    context = []
    return context unless warning.line and file and @app_tree.path_exists? file

    current_line = 0
    start_line = warning.line - 5
    end_line = warning.line + 5

    start_line = 1 if start_line < 0

    File.open file do |f|
      f.each_line do |line|
        current_line += 1

        next if line.strip == ""

        if current_line > end_line
          break
        end

        if current_line >= start_line
          context << [current_line, line]
        end
      end
    end

    context
  end

  def relative_path file
    pname = Pathname.new file
    if file and not file.empty? and pname.absolute?
      pname.relative_path_from(Pathname.new(@tracker.app_path)).to_s
    else
      file
    end
  end

  #Convert path/filename to view name
  #
  # views/test/something.html.erb -> test/something
  def template_path_to_name path
    names = path.split("/")
    names.last.gsub!(/(\.(html|js)\..*|\.(rhtml|haml|erb|slim))$/, '')
    names[(names.index("views") + 1)..-1].join("/").to_sym
  end

  def github_url file, line=nil
    if repo_url = @tracker.options[:github_url] and file and not file.empty? and file.start_with? '/'
      url = "#{repo_url}/#{relative_path(file)}"
      url << "#L#{line}" if line
    else
      nil
    end
  end

  def truncate_table str
    @terminal_width ||= if @tracker.options[:table_width]
                          @tracker.options[:table_width]
                        elsif $stdin && $stdin.tty?
                          Brakeman.load_brakeman_dependency 'highline'
                          ::HighLine.new.terminal_size[0]
                        else
                          80
                        end
    lines = str.lines

    lines.map do |line|
      if line.chomp.length > @terminal_width
        line[0..(@terminal_width - 3)] + ">>\n"
      else
        line
      end
    end.join
  end

  # rely on Terminal::Table to build the structure, extract the data out in CSV format
  def table_to_csv table
    return "" unless table

    Brakeman.load_brakeman_dependency 'terminal-table'
    headings = table.headings
    if headings.is_a? Array
      headings = headings.first
    end

    output = CSV.generate_line(headings.cells.map{|cell| cell.to_s.strip})
    table.rows.each do |row|
      output << CSV.generate_line(row.cells.map{|cell| cell.to_s.strip})
    end
    output
  end
end
