module Brakeman
  module Logger
    def self.get_logger options
      dest = $stderr
   
      case
      when options[:debug]
        Debug.new(options)
      when options[:quiet]
        Quiet.new(options)
      when dest.tty?
        Console.new(options)
      end
    end

    class Base
      def initialize options
        @dest = $stderr
      end

      def log(message, newline: true)
        if newline
          @dest.puts message
        else
          @dest.write message
        end
      end

      def cleanup
      end
    end

    class Quiet < Base
    end
    
    class Console < Base
      attr_reader :prefix
      
      def initialize(options = nil)
        super

        Brakeman.load_brakeman_dependency('highline')
        require 'reline'
        require 'reline/io/ansi'

        @prefix = ''
        @post_fix_pos = 0
        @reline = Reline::ANSI.new
        @highline = HighLine.new
        @report_progress = options[:report_progress]
        @spinner = ["⣀", "⣄", "⣤", "⣦", "⣶", "⣷", "⣿"]
        @percenter = ["⣀", "⣤", "⣶", "⣿"]
        @spindex = 0
        @last_spin = Time.now
        @reline.hide_cursor
      end

      def announce message
        clear_line
        log @highline.color(message, :green)
      end

      def context description, &block
        write_prefix description
        yield self
      ensure
        clear_prefix
      end

      def update_status status
        write_after status
      end

      def update_progress current, total, type = 'files'
        percent = ((current / total.to_f) * 100).to_i
        tenths = [(percent / 10), 0].max

        lead = @highline.color(@percenter[percent % 10 / 3], :bold, :red)
        done_blocks = @highline.color("⣿" * tenths, :red)
        remaining = @highline.color("⣀" * (9 - tenths), :gray)
        write_after "#{done_blocks}#{lead}#{remaining}"
      end

      def write_prefix pref
        set_prefix pref
        log(prefix, newline: false)
        @reline.erase_after_cursor
      end

      def write_after message
        @reline.move_cursor_column(@post_fix_pos)
        log(message, newline: false)
        @reline.erase_after_cursor
      end

      def set_prefix message
        @prefix = "#{@highline.color('»', :bold, :cyan)} #{@highline.color(message, :green)}"
        @post_fix_pos = HighLine::Wrapper.actual_length(@prefix) + 1
      end

      def clear_prefix
        @prefix = ''
        @post_fix_pos = 0
        clear_line
      end

      def clear_line
        @reline.move_cursor_column(0)
        @reline.erase_after_cursor
      end

      def spin
        return unless (Time.now - @last_spin) > 0.2

        write_after @highline.color(@spinner[@spindex], :bold, :red)
        @spindex = (@spindex + 1) % @spinner.length
        @last_spin = Time.now
      end

      def cleanup
        @reline.show_cursor
        log('')
      end
    end
  end
end
