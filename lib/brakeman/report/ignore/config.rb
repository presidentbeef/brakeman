require 'set'
require 'multi_json'

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
      @already_ignored.reject! do |w|
        w[:fingerprint] == warning.fingerprint
      end
    end

    # Determine if warning should be ignored
    def ignored? warning
      @ignored_fingerprints.include? warning.fingerprint
    end

    def ignore warning
      @ignored_fingerprints << warning.fingerprint
    end

    # Add note for warning
    def add_note warning, note
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
        @already_ignored = MultiJson.load(File.read(file), :symbolize_keys => true)[:ignored_warnings]
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
      end

      output = {
        :ignored_warnings => warnings,
        :updated => Time.now.to_s,
        :brakeman_version => Brakeman::Version
      }

      File.open file, "w" do |f|
        f.puts MultiJson.dump(output, :pretty => true)
      end
    end

    # Save old ignored warnings and newly ignored ones
    def save_with_old
      warnings = @ignored_warnings.dup

      # Only add ignored warnings not already ignored
      @already_ignored.each do |w|
        fingerprint = w[:fingerprint]

        unless @ignored_warnings.find { |w| w.fingerprint == fingerprint }
          warnings << w
        end
      end

      save_to_file warnings
    end
  end
end
