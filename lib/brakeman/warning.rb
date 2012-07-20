require 'digest/md5'

#The Warning class stores information about warnings
class Brakeman::Warning
  attr_reader :called_from, :check, :class, :confidence, :controller,
    :line, :method, :model, :template, :user_input, :warning_set, :warning_type

  attr_accessor :code, :context, :file, :message

  TEXT_CONFIDENCE = [ "High", "Medium", "Weak" ]

  #+options[:result]+ can be a result from Tracker#find_call. Otherwise, it can be +nil+.
  def initialize options = {}
    @view_name = nil

    [:called_from, :check, :class, :code, :confidence, :controller, :file, :line,
      :message, :method, :model, :template, :user_input, :warning_set, :warning_type].each do |option|

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

  #Return String of the user input formatted and
  #stripped of newlines and tabs.
  def format_user_input
    Brakeman::OutputProcessor.new.format(self.user_input).gsub(/(\t|\r|\n)+/, " ")
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

  def to_hash
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

    { :warning_type => self.warning_type,
      :message => self.message,
      :file => self.file,
      :line => self.line,
      :code => (@code && self.format_code),
      :location => location,
      :user_input => (@user_input && self.format_user_input),
      :confidence => TEXT_CONFIDENCE[self.confidence]
    }
  end

  def to_json
    require 'json'

    JSON.dump self.to_hash
  end

  def to_annotation
    clean_for_annotation.merge({:digest => self.annotation_digest, :note => ""})
  end

  def clean_for_annotation
    h = self.to_hash
    h.delete(:line)
    h
  end

  def annotation_digest
    digested = ""
    clean_for_annotation.keys.map(&:to_s).sort.each do |k|
      digested << k << self.to_hash[k.to_sym].to_s
    end

    digest = Digest::MD5.hexdigest(digested)
    if RUBY_VERSION >= "1.9"
      digest.force_encoding("UTF-8")
    end
    digest
  end
end
