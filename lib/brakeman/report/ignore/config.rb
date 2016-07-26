require 'set'
require 'json'

module Brakeman
  class IgnoreConfig
    attr_reader :shown_warnings, :ignored_warnings
    attr_accessor :file

    def initialize file, new_warnings
      @file = file
      @new_warnings = new_warnings
      @already_ignored = []
      @ignored_fingerprints = Set.new
      @notes = {}
      @shown_warnings = @ignored_warnings = nil
      @changed = false
    end

    # Populate ignored_warnings and shown_warnings based on ignore
    # configuration
    def filter_ignored
      @shown_warnings = []
      @ignored_warnings = []

      @new_warnings.each do |w|
        if ignored? w
          @ignored_warnings << w
        else
          @shown_warnings << w
        end
      end

      @shown_warnings
    end

    # Remove warning from ignored list
    def unignore warning
      @ignored_fingerprints.delete warning.fingerprint
      if @already_ignored.reject! { |w|w[:fingerprint] == warning.fingerprint }
        @changed = true
      end
    end

    # Determine if warning should be ignored
    def ignored? warning
      @ignored_fingerprints.include? warning.fingerprint
    end

    def ignore warning
      @changed = true unless ignored? warning
      @ignored_fingerprints << warning.fingerprint
    end

    # Add note for warning
    def add_note warning, note
      @changed = true
      @notes[warning.fingerprint] = note
    end

    # Retrieve note for warning if it exists. Returns nil if no
    # note is found
    def note_for warning
      if warning.is_a? Warning
        fingerprint = warning.fingerprint
      else
        fingerprint = warning[:fingerprint]
      end

      @already_ignored.each do |w|
        if fingerprint == w[:fingerprint]
          return w[:note]
        end
      end

      nil
    end

    # Read configuration to file
    def read_from_file file = @file
      if File.exist? file
        @already_ignored = JSON.parse(File.read(file), :symbolize_names => true)[:ignored_warnings]
      else
        Brakeman.notify "[Notice] Could not find ignore configuration in #{file}"
        @already_ignored = []
      end

      @already_ignored.each do |w|
        @ignored_fingerprints << w[:fingerprint]
        @notes[w[:fingerprint]] = w[:note]
      end
    end

    # Save configuration to file
    def save_to_file warnings, file = @file
      warnings = warnings.map do |w|
        if w.is_a? Warning
          w_hash = w.to_hash
          w_hash[:file] = w.relative_path
          w = w_hash
        end

        w[:note] = @notes[w[:fingerprint]] || ""
        w
      end.sort_by { |w| w[:fingerprint] }

      # For each white listed entry, we check if it's already in the ignored list, if not,
      # we write them out.
      @total_ignored ||= @already_ignored
      warnings.reject! { |r| @ignored_fingerprints.include? r[:fingerprint] }
      @total_ignored += warnings
      output = {
        :ignored_warnings => @total_ignored,
        :updated => Time.now.to_s,
        :brakeman_version => Brakeman::Version
      }

      File.open file, "w" do |f|
        f.puts JSON.pretty_generate(output)
      end

    end

    # Save old ignored warnings and newly ignored ones
    def save_with_old warning = nil, changed = false
      warnings = warning || @ignored_warnings.dup

      # Only add ignored warnings not already ignored
      @already_ignored.each do |w|
        fingerprint = w[:fingerprint]

        unless @ignored_warnings.find { |ignored_warning| ignored_warning.fingerprint == fingerprint }
          warnings << w
        end
      end

      if @changed or changed
        save_to_file warnings
      end
    end
  end
end
