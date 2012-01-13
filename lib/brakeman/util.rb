require 'sexp_processor'
require 'set'
require 'active_support/inflector'

#This is a mixin containing utility methods.
module Brakeman::Util

  QUERY_PARAMETERS = Sexp.new(:call, Sexp.new(:call, nil, :request, Sexp.new(:arglist)), :query_parameters, Sexp.new(:arglist))

  PATH_PARAMETERS = Sexp.new(:call, Sexp.new(:call, nil, :request, Sexp.new(:arglist)), :path_parameters, Sexp.new(:arglist))

  REQUEST_PARAMETERS = Sexp.new(:call, Sexp.new(:call, nil, :request, Sexp.new(:arglist)), :request_parameters, Sexp.new(:arglist))

  PARAMETERS = Sexp.new(:call, nil, :params, Sexp.new(:arglist))

  COOKIES = Sexp.new(:call, nil, :cookies, Sexp.new(:arglist))

  SESSION = Sexp.new(:call, nil, :session, Sexp.new(:arglist))

  ALL_PARAMETERS = Set.new([PARAMETERS, QUERY_PARAMETERS, PATH_PARAMETERS, REQUEST_PARAMETERS])

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

  #Use ActiveSupport::Inflector to pluralize a word.
  def pluralize word
    ActiveSupport::Inflector.pluralize word
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

  #Adds params, session, and cookies to environment
  #so they can be replaced by their respective Sexps.
  def set_env_defaults
    @env[PARAMETERS] = Sexp.new(:params)
    @env[SESSION] = Sexp.new(:session)
    @env[COOKIES] = Sexp.new(:cookies)
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

  #Check if _exp_ represents a Symbol: s(:lit, :...)
  def symbol? exp
    exp.is_a? Sexp and exp.node_type == :lit and exp[1].is_a? Symbol
  end

  #Check if _exp_ represents a method call: s(:call, ...)
  def call? exp
    exp.is_a? Sexp and exp.node_type == :call
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

  #Check if _exp_ is a params hash
  def params? exp
    if exp.is_a? Sexp
      return true if exp.node_type == :params or ALL_PARAMETERS.include? exp

      if exp.node_type == :call
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
      return true if exp.node_type == :cookies or exp == COOKIES

      if exp.node_type == :call
        if cookies? exp[1]
          return true
        elsif exp[2] == :[]
          return cookies? exp[1]
        end
      end
    end

    false

  end

  #Check if _exp_ is a Sexp.
  def sexp? exp
    exp.is_a? Sexp
  end

  #Return file name related to given warning. Uses +warning.file+ if it exists
  def file_for warning, tracker = nil
    if tracker.nil?
      tracker = @tracker || self.tracker
    end

    if warning.file
      File.expand_path warning.file, tracker.options[:app_path]
    else
      case warning.warning_set
      when :controller
        file_by_name warning.controller, :controller, tracker
      when :template
        file_by_name warning.template[:name], :template, tracker
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
      elsif camelize(string_name) == string_name
        type = :model
      else
        type = :template
      end
    end

    path = tracker.options[:app_path]

    case type
    when :controller
      if tracker.controllers[name] and tracker.controllers[name][:file]
        path = tracker.controllers[name][:file]
      else
        path += "/app/controllers/#{underscore(string_name)}.rb"
      end
    when :model
      if tracker.models[name] and tracker.models[name][:file]
        path = tracker.models[name][:file]
      else
        path += "/app/controllers/#{underscore(string_name)}.rb"
      end
    when :template
      if tracker.templates[name] and tracker.templates[name][:file]
        path = tracker.templates[name][:file]
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
  def context_for warning, tracker = nil
    file = file_for warning, tracker
    context = []
    return context unless warning.line and file and File.exist? file

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
end
