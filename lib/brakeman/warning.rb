require 'multi_json'
require 'digest/sha2'
require 'brakeman/warning_codes'

#The Warning class stores information about warnings
class Brakeman::Warning
  attr_reader :called_from, :check, :class, :confidence, :controller,
    :line, :method, :model, :template, :user_input, :warning_code, :warning_set,
    :warning_type

  attr_accessor :code, :context, :file, :message, :relative_path

  TEXT_CONFIDENCE = [ "High", "Medium", "Weak" ]

  #+options[:result]+ can be a result from Tracker#find_call. Otherwise, it can be +nil+.
  def initialize options = {}
    @view_name = nil

    [:called_from, :check, :class, :code, :confidence, :controller, :file, :line, :link_path,
      :message, :method, :model, :relative_path, :template, :user_input, :warning_set, :warning_type].each do |option|

      self.instance_variable_set("@#{option}", options[option])
    end

    result = options[:result]
    if result
      @code ||= result[:call]
      @file ||= result[:location][:file]

      if result[:location][:type] == :template #template result
        @template ||= result[:location][:template]
      else
        @class ||= result[:location][:class]
        @method ||= result[:location][:method]
      end
    end

    if not @line
      if @user_input and @user_input.respond_to? :line
        @line = @user_input.line
      elsif @code and @code.respond_to? :line
        @line = @code.line
      end
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

    if options[:warning_code]
      @warning_code = Brakeman::WarningCodes.code options[:warning_code]
    end

    Brakeman.debug("Warning created without warning code: #{options[:warning_code]}") unless @warning_code

    @format_message = nil
    @row = nil
  end

  def hash
    self.to_s.hash
  end

  def eql? other_warning
    self.hash == other_warning.hash
  end

  #Returns name of a view, including where it was rendered from
  def view_name
    return @view_name if @view_name
    if called_from
      @view_name = "#{template[:name]} (#{called_from.last})"
    else
      @view_name = template[:name]
    end
  end

  #Return String of the code output from the OutputProcessor and
  #stripped of newlines and tabs.
  def format_code strip = true
    format_ruby self.code, strip
  end

  #Return String of the user input formatted and
  #stripped of newlines and tabs.
  def format_user_input strip = true
    format_ruby self.user_input, strip
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

  def link
    return @link if @link

    if @link_path
      if @link_path.start_with? "http"
        @link = @link_path
      else
        @link = "http://brakemanscanner.org/docs/warning_types/#{@link_path}"
      end
    else
      warning_path = self.warning_type.to_s.downcase.gsub(/\s+/, '_') + "/"
      @link = "http://brakemanscanner.org/docs/warning_types/#{warning_path}"
    end

    @link
  end

  #Generates a hash suitable for inserting into a table
  def to_row type = :warning
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

  def to_s
   output =  "(#{TEXT_CONFIDENCE[self.confidence]}) #{self.warning_type} - #{self.message}"
   output << " near line #{self.line}" if self.line
   output << " in #{self.file}" if self.file
   output << ": #{self.format_code}" if self.code

   output
  end

  def fingerprint
    loc = self.location
    location_string = loc && loc.sort_by { |k, v| k.to_s }.inspect
    warning_code_string = sprintf("%03d", @warning_code)
    code_string = @code.inspect

    Digest::SHA2.new(256).update("#{warning_code_string}#{code_string}#{location_string}#{@relative_path}#{self.confidence}").to_s
  end

  def location
    case @warning_set
    when :template
      location = { :type => :template, :template => self.view_name }
    when :model
      location = { :type => :model, :model => self.model }
    when :controller
      location = { :type => :controller, :controller => self.controller }
    when :warning
      if self.class
        location = { :type => :method, :class => self.class, :method => self.method }
      else
        location = nil
      end
    end
  end

  def to_hash
    { :warning_type => self.warning_type,
      :warning_code => @warning_code,
      :fingerprint => self.fingerprint,
      :message => self.message,
      :file => self.file,
      :line => self.line,
      :link => self.link,
      :code => (@code && self.format_code(false)),
      :render_path => self.called_from,
      :location => self.location,
      :user_input => (@user_input && self.format_user_input(false)),
      :confidence => TEXT_CONFIDENCE[self.confidence]
    }
  end

  def to_json
    MultiJson.dump self.to_hash
  end

  private

  def format_ruby code, strip
    formatted = Brakeman::OutputProcessor.new.format(code)
    formatted.gsub!(/(\t|\r|\n)+/, " ") if strip
    formatted
  end
end

