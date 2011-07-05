require 'warning_types'

#The Warning class stores information about warnings
class Warning
  include WarningTypes
  attr_reader :called_from, :check, :class, :confidence, :controller,
    :line, :method, :model, :template, :warning_set, :warning_type

  attr_accessor :code, :context, :file, :message

  #+options[:result]+ can be a result Sexp from FindCall. Otherwise, it can be +nil+.
  def initialize options = {}
    @view_name = nil

    [:called_from, :check, :class, :code, :confidence, :controller, :file, :line,
      :message, :method, :model, :template, :warning_set, :warning_type].each do |option|

      self.instance_variable_set("@#{option}", options[option])
    end

    result = options[:result]
    if result
      if result.length == 3 #template result
        @template ||= result[1]
        @code ||= result[2]
      else
        @class ||= result[1]
        @method ||= result[2]
        @code ||= result[3]
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
    OutputProcessor.new.format(self.code).gsub(/(\t|\r|\n)+/, " ")
  end

  #Return formatted warning message
  def format_message
    message = self.message

    if self.line
      message << " near line #{self.line}"
    end

    if self.code
      message << ": #{format_code}"
    end
    message
  end

  def warning_type_collapsible warning_type
    random_id = (0...8).map{65.+(rand(25)).chr}.join
    description = WarningTypes.description[warning_type]
    return warning_type unless description
    <<-HTML
    <div class='warning_type' onclick=\"toggle('#{random_id}');\">
        #{warning_type}
        <div class='warning_type_extended' id='#{random_id}'>
        #{description}
        </div>
    </div>
    HTML
  end

  #Generates a hash suitable for inserting into a Ruport table
  def to_row type = :warning
    row = { "Confidence" => self.confidence,
      "Message" => self.format_message }

    if OPTIONS[:output_format] == :to_html
      row["Warning Type"] = warning_type_collapsible self.warning_type.to_s
    else
        row["Warning Type"] = self.warning_type.to_s
    end
    case type
    when :template
      row["Template"] = self.view_name.to_s
    when :model
      row["Model"] = self.model.to_s
    when :controller
      row["Controller"] = self.controller.to_s
    when :warning
      row["Class"] = self.class.to_s
      row["Method"] = self.method.to_s
    end

    row
  end
end
