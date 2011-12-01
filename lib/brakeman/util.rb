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

  #Check if _exp_ represents a result: s(:result, ...)
  def result? exp
    exp.is_a? Sexp and exp.node_type == :result
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
end
