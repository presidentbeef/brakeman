require 'set'

#Stores call sites to look up later.
class Brakeman::CallIndex

  #Initialize index with calls from FindAllCalls
  def initialize calls
    @calls_by_method = Hash.new { |h, k| h[k] = [] }
    @calls_by_target = Hash.new { |h, k| h[k] = [] }

    index_calls calls
  end

  #Find calls matching specified option hash.
  #
  #Options:
  #
  #  * :target - symbol, array of symbols, or regular expression to match target(s)
  #  * :method - symbol, array of symbols, or regular expression to match method(s)
  #  * :chained - boolean, whether or not to match against a whole method chain (false by default)
  #  * :nested - boolean, whether or not to match against a method call that is a target itself (false by default)
  def find_calls options
    target = options[:target] || options[:targets]
    method = options[:method] || options[:methods]
    nested = options[:nested]

    if options[:chained]
      return find_chain options
    #Find by narrowest category
    elsif target and method and target.is_a? Array and method.is_a? Array
      if target.length > method.length
        calls = filter_by_target calls_by_methods(method), target
      else
        calls = calls_by_targets(target)
        calls = filter_by_method calls, method
      end

    #Find by target, then by methods, if provided
    elsif target
      calls = calls_by_target target

      if calls and method
        calls = filter_by_method calls, method
      end

    #Find calls with no explicit target
    #with either :target => nil or :target => false
    elsif (options.key? :target or options.key? :targets) and not target and method
      calls = calls_by_method method
      calls = filter_by_target calls, nil

    #Find calls by method
    elsif method
      calls = calls_by_method method
    else
      raise "Invalid arguments to CallCache#find_calls: #{options.inspect}"
    end

    return [] if calls.nil?

    #Remove calls that are actually targets of other calls
    #Unless those are explicitly desired
    calls = filter_nested calls unless nested

    calls
  end

  def remove_template_indexes template_name = nil
    [@calls_by_method, @calls_by_target].each do |calls_by|
      calls_by.each do |_name, calls|
        calls.delete_if do |call|
          from_template call, template_name
        end
      end
    end
  end

  def remove_indexes_by_class classes
    [@calls_by_method, @calls_by_target].each do |calls_by|
      calls_by.each do |_name, calls|
        calls.delete_if do |call|
          call[:location][:type] == :class and classes.include? call[:location][:class]
        end
      end
    end
  end

  def index_calls calls
    calls.each do |call|
      @calls_by_method[call[:method]] << call

      target = call[:target]

      if not target.is_a? Sexp
        @calls_by_target[target] << call
      elsif target.node_type == :params or target.node_type == :session
        @calls_by_target[target.node_type] << call
      end
    end
  end

  private

  def find_chain options
    target = options[:target] || options[:targets]
    method = options[:method] || options[:methods]

    calls = calls_by_method method

    return [] if calls.nil?

    calls = filter_by_chain calls, target
  end

  def calls_by_target target
    if target.is_a? Array
      calls_by_targets target
    else
      @calls_by_target[target]
    end
  end

  def calls_by_targets targets
    calls = []

    targets.each do |target|
      calls.concat @calls_by_target[target] if @calls_by_target.key? target
    end

    calls
  end

  def calls_by_method method
    if method.is_a? Array
      calls_by_methods method
    elsif method.is_a? Regexp
      calls_by_methods_regex method
    else
      @calls_by_method[method.to_sym]
    end
  end

  def calls_by_methods methods
    methods = methods.map { |m| m.to_sym }
    calls = []

    methods.each do |method|
      calls.concat @calls_by_method[method] if @calls_by_method.key? method
    end

    calls
  end

  def calls_by_methods_regex methods_regex
    calls = []
    @calls_by_method.each do |key, value|
      calls.concat value if key.to_s.match methods_regex
    end
    calls
  end

  def calls_with_no_target
    @calls_by_target[nil]
  end

  def filter calls, key, value
    if value.is_a? Array
      values = Set.new value

      calls.select do |call|
        values.include? call[key]
      end
    elsif value.is_a? Regexp
      calls.select do |call|
        call[key].to_s.match value
      end
    else
      calls.select do |call|
        call[key] == value
      end
    end
  end

  def filter_by_method calls, method
    filter calls, :method, method
  end

  def filter_by_target calls, target
    filter calls, :target, target
  end

  def filter_nested calls
    filter calls, :nested, false
  end

  def filter_by_chain calls, target
    if target.is_a? Array
      targets = Set.new target

      calls.select do |call|
        targets.include? call[:chain].first
      end
    elsif target.is_a? Regexp
      calls.select do |call|
        call[:chain].first.to_s.match target
      end
    else
      calls.select do |call|
        call[:chain].first == target
      end
    end
  end

  def from_template call, template_name
    return false unless call[:location][:type] == :template
    return true if template_name.nil?
    call[:location][:template] == template_name
  end
end
