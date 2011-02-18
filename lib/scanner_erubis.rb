begin
  require 'erubis'
rescue LoadError => e
  $stderr.puts e.message
  $stderr.puts "Please install Erubis."
  exit!
end

#This is from the rails_xss plugin,
#except we don't care about plain text.
class RailsXSSErubis < ::Erubis::Eruby
  include Erubis::NoTextEnhancer

  #Initializes output buffer.
  def add_preamble(src)
    src << "@output_buffer = ActionView::SafeBuffer.new;\n"
  end

  #This does nothing.
  def add_text(src, text)
    #    src << "@output_buffer << ('" << escape_text(text) << "'.html_safe!);"
  end

  #Add an expression to the output buffer _without_ escaping.
  def add_expr_literal(src, code)
    src << '@output_buffer << ((' << code << ').to_s);'
  end

  #Add an expression to the output buffer after escaping it.
  def add_expr_escaped(src, code)
    src << '@output_buffer << ' << escaped_expr(code) << ';'
  end

  #Add code to output buffer.
  def add_postamble(src)
    src << '@output_buffer.to_s'
  end
end

#Erubis processor which ignores any output which is plain text.
class ScannerErubis < Erubis::Eruby
  include Erubis::NoTextEnhancer
end
