Dir[File.dirname(__FILE__) + '/overviews/*.rb'].each {|file| require file}

class Brakeman::Report
  class Overview
    include Brakeman::Util

    def initialize(app_tree, tracker, all_warnings)
      @app_tree = app_tree
      @tracker = tracker
      @all_warnings = all_warnings
      @warnings_summary = nil
      @element_id = 0 #Used for HTML ids
    end

    def report(html = false)
      raise 'this should be implemented'
    end

    private

    def render_array(template, headings, value_array, locals, html = false)
      return if value_array.empty?
      if html
        Brakeman::Report::Renderer.new(template, :locals => locals).render
      else
        Terminal::Table.new(:headings => headings) do |t|
          value_array.each { |value_row| t.add_row value_row }
        end
      end
    end

    # Return summary of warnings in hash and store in @warnings_summary
    def warnings_summary
      return @warnings_summary if @warnings_summary

      summary = Hash.new(0)
      high_confidence_warnings = 0

      [@all_warnings].each do |warnings|
        warnings.each do |warning|
          summary[warning.warning_type.to_s] += 1
          high_confidence_warnings += 1 if warning.confidence == 0
        end
      end

      summary[:high_confidence] = high_confidence_warnings
      @warnings_summary = summary
    end

    def number_of_templates tracker
      Set.new(tracker.templates.map {|k,v| v[:name].to_s[/[^.]+/]}).length
    end

    #Escape warning message and highlight user input in text output
    def text_message warning, message
      if @tracker.options[:highlight_user_input] and warning.user_input
        user_input = warning.format_user_input
        message.gsub(user_input, "+#{user_input}+")
      else
        message
      end
    end

    #Escape warning message and highlight user input in HTML output
    def html_message warning, message
      message = CGI.escapeHTML(message)

      if @highlight_user_input and warning.user_input
        user_input = CGI.escapeHTML(warning.format_user_input)
        message.gsub!(user_input, "<span class=\"user_input\">#{user_input}</span>")
      end

      message
    end

    #Generate HTML for warnings, including context show/hidden via Javascript
    def with_context warning, message
      context = context_for(@app_tree, warning)
      full_message = nil

      if @tracker.options[:message_limit] and @tracker.options[:message_limit] > 0 and message.length > @tracker.options[:message_limit]
        full_message = html_message(warning, message)
        message = message[0..@tracker.options[:message_limit]] << "..."
      end

      message = html_message(warning, message)
      return message if context.empty? and not full_message

      @element_id += 1
      code_id = "context#@element_id"
      message_id = "message#@element_id"
      full_message_id = "full_message#@element_id"
      alt = false
      output = "<div class='warning_message' onClick=\"toggle('#{code_id}');toggle('#{message_id}');toggle('#{full_message_id}')\" >" <<
      if full_message
        "<span id='#{message_id}' style='display:block' >#{message}</span>" <<
        "<span id='#{full_message_id}' style='display:none'>#{full_message}</span>"
      else
        message
      end <<
      "<table id='#{code_id}' class='context' style='display:none'>" <<
      "<caption>#{warning_file(warning, :relative) || ''}</caption>"

      unless context.empty?
        if warning.line - 1 == 1 or warning.line + 1 == 1
          error = " near_error"
        elsif 1 == warning.line
          error = " error"
        else
          error = ""
        end

        output << <<-HTML
          <tr class='context first#{error}'>
            <td class='context_line'>
              <pre class='context'>#{context.first[0]}</pre>
            </td>
            <td class='context'>
              <pre class='context'>#{CGI.escapeHTML context.first[1].chomp}</pre>
            </td>
          </tr>
        HTML

        if context.length > 1
          output << context[1..-1].map do |code|
            alt = !alt
            if code[0] == warning.line - 1 or code[0] == warning.line + 1
              error = " near_error"
            elsif code[0] == warning.line
              error = " error"
            else
              error = ""
            end

            <<-HTML
            <tr class='context#{alt ? ' alt' : ''}#{error}'>
              <td class='context_line'>
                <pre class='context'>#{code[0]}</pre>
              </td>
              <td class='context'>
                <pre class='context'>#{CGI.escapeHTML code[1].chomp}</pre>
              </td>
            </tr>
            HTML
          end.join
        end
      end

      output << "</table></div>"
    end

    def with_link warning, message
      "<a rel=\"no-referrer\" href=\"#{warning.link}\">#{message}</a>"
    end

    def warning_file warning, relative = false
      return nil if warning.file.nil?

      if @tracker.options[:relative_paths] or relative
        relative_path warning.file
      else
        warning.file
      end
    end

  end
end