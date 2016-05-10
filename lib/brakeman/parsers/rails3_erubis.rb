Brakeman.load_brakeman_dependency 'erubis'

#This is from Rails 3 version of the Erubis handler
class Brakeman::Rails3Erubis < ::Erubis::Eruby

  def add_preamble(src)
    # src << "_buf = ActionView::SafeBuffer.new;\n"
  end

  #This is different from Rails 3 - fixes some line number issues
  def add_text(src, text)
    lines = text.lines
    lines.each do |line|
      if line == "\n"
        src << line
      else
        newline = line.end_with?("\n") ? "\n" : nil
        src << "@output_buffer << ('" << escape_text(line.chomp) << "'.html_safe!);#{newline}"
      end
    end
  end

  BLOCK_EXPR = /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/

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
      src << "@output_buffer.safe_append= (" << code << ");"
    end
  end

  #Add code to output buffer.
  def add_postamble(src)
    # src << '_buf.to_s'
  end
end
