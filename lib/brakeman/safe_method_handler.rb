class SafeMethodHandler
  def self.normalize_method(method)
    case method
    when Symbol
      method
    when String
      has_namespace?(method) ? normalize_method_delimeter(method) : method.to_sym
    else
      raise ArgumentError, "Method must be a String or Symbol"
    end
  end

  def self.parse_method_identifier(identifier)
    case identifier
    when Symbol
      { class_name: nil, method_name: identifier }
    when String
      if identifier.include?('.')
        class_name, method_name = identifier.split('.')
        { class_name: class_name, method_name: method_name.to_sym }
      else
        { class_name: nil, method_name: identifier.to_sym }
      end
    else
      raise ArgumentError, "Method identifier must be a String or Symbol"
    end
  end

  def self.matches?(target_method, ignored_method)
    target = parse_method_identifier(target_method)
    ignored = parse_method_identifier(ignored_method)

    # If ignored method has no class specified, only check method name
    return target[:method_name] == ignored[:method_name] if ignored[:class_name].nil?

    # If class is specified, both class and method must match
    target[:class_name] == ignored[:class_name] && 
      target[:method_name] == ignored[:method_name]
  end

  def self.include?(target_method, ignored_methods)
    ignored_methods.any? { |ignored| matches?(target_method, ignored) }
  end

  private

  def self.normalize_method_delimeter(identifier)
    identifier.gsub(/(::|#)/, '.')
  end

  def self.has_namespace?(m)
    m.include?('::') || m.include?('#') || m.include?('.')
  end
end
