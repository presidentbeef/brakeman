#The Warning class stores information about warnings
class Brakeman::Warning
  attr_reader :called_from, :check, :class, :confidence, :controller,
    :line, :method, :model, :template, :warning_set, :warning_type

  attr_accessor :code, :context, :file, :message

  #+options[:result]+ can be a result from Tracker#find_call. Otherwise, it can be +nil+.
  def initialize options = {}
    @view_name = nil

    [:called_from, :check, :class, :code, :confidence, :controller, :file, :line,
      :message, :method, :model, :template, :warning_set, :warning_type].each do |option|

      self.instance_variable_set("@#{option}", options[option])
    end

    result = options[:result]
    if result
      if result[:location][0] == :template #template result
        @template ||= result[:location][1]
        @code ||= result[:call]
      else
        @class ||= result[:location][1]
        @method ||= result[:location][2]
        @code ||= result[:call]
      end
    end

    if @code and not @line and @code.respond_to? :line
      @line = @code.line
    end

    unless @warning_set
      if self.model
        @warning_set = :model
      elsif self.template
        @warning_set = :template
        @called_from = self.template[:caller]
      elsif self.controller
        @warning_set = :controller
      else
        @warning_set = :warning
      end
    end

    @format_message = nil
    @row = nil
  end

  def hash
    self.format_message.hash
  end

  def eql? other_warning
    self.hash == other_warning.hash
  end

  #Returns name of a view, including where it was rendered from
  def view_name
    return @view_name if @view_name
    if called_from
      @view_name = "#{template[:name]} (#{called_from})"
    else
      @view_name = template[:name]
    end
  end

  #Return String of the code output from the OutputProcessor and
  #stripped of newlines and tabs.
  def format_code
    Brakeman::OutputProcessor.new.format(self.code).gsub(/(\t|\r|\n)+/, " ")
  end

  #Return formatted warning message
  def format_message
    return @format_message if @format_message

    @format_message = self.message.dup

    if self.line
      @format_message << " near line #{self.line}"
    end

    if self.code
      @format_message << ": #{format_code}"
    end

    @format_message
  end

  #Generates a hash suitable for inserting into a Ruport table
  def to_row type = :warning
    return @row if @row

    @row = { "Confidence" => self.confidence,
      "Warning Type" => self.warning_type.to_s,
      "Message" => self.format_message }

    case type
    when :template
      @row["Template"] = self.view_name.to_s
    when :model
      @row["Model"] = self.model.to_s
    when :controller
      @row["Controller"] = self.controller.to_s
    when :warning
      @row["Class"] = self.class.to_s
      @row["Method"] = self.method.to_s
    end

    @row
  end
end
