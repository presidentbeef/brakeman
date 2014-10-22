Brakeman.load_brakeman_dependency 'erubis'

#This is from Rails 3 version of the Erubis handler
class Brakeman::Rails3Erubis < ::Erubis::Eruby

  def add_preamble(src)
    # src << "_buf = ActionView::SafeBuffer.new;\n"
  end

  #This is different from Rails 3 - fixes some line number issues
  def add_text(src, text)
    if text == "\n"
      src << "\n"
    elsif text.include? "\n"
      lines = text.split("\n")
      if text.match(/\n\z/)
        lines.each do |line|
          src << "@output_buffer << ('" << escape_text(line) << "'.html_safe!);\n"
        end
      else
        lines[0..-2].each do |line|
          src << "@output_buffer << ('" << escape_text(line) << "'.html_safe!);\n"
        end

        src << "@output_buffer << ('" << escape_text(lines.last) << "'.html_safe!);"
      end
    else
      src << "@output_buffer << ('" << escape_text(text) << "'.html_safe!);"
    end
  end

  BLOCK_EXPR = /\s+(do|\{)(\s*\|[^|]*\|)?\s*\Z/

  def add_expr_literal(src, code)
    if code =~ BLOCK_EXPR
      src << '@output_buffer.append= ' << code
    else
      src << '@output_buffer.append= (' << code << ');'
    end
  end

  def add_expr_escaped(src, code)
    if code =~ BLOCK_EXPR
      src << "@output_buffer.safe_append= " << code
    else
      src << "@output_buffer.safe_concat(" << code << ");"
    end
  end

  #Add code to output buffer.
  def add_postamble(src)
    # src << '_buf.to_s'
  end
end
