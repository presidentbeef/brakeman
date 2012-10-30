class ERB
  module Util

    if "html_safe exists".respond_to?(:html_safe)
      def html_escape(s)
        s = s.to_s
        if s.html_safe?
          s
        else
          Rack::Utils.escape_html(s).html_safe
        end
      end
    else
      def html_escape(s)
        s = s.to_s
        Rack::Utils.escape_html(s).html_safe
      end
    end

    remove_method :h
    alias h html_escape

    class << self
      remove_method :html_escape
      remove_method :h
    end

    module_function :html_escape
    module_function :h
  end
end
