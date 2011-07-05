require 'digest/md5'

module Blessing


    @@BLESSING_FILE = File.join(OPTIONS[:app_path], 'test/brakeman/blessed.rb')

    #load the user-defined blessings
    begin
        require "#{@@BLESSING_FILE}"
        blessings = Blessings.blessings
    rescue LoadError => e
        puts "Unable to load blessings file (#{@@BLESSING_FILE}), continuing without it. Exception: #{e.message}"
        blessings = []
    end
    #put the blessings into an Hash of hash :=> true
    @@blessings_hash = Hash.new
    blessings.each do |hash|
        @@blessings_hash[hash] = true
    end

    def self.is_blessed?(result)
        hash = self.hash_result result
        @@blessings_hash[hash]
    end

    def self.hash_result (result)
        Digest::MD5.hexdigest("#{result.class}\n#{result.code.to_s}\n#{result.message}\n#{result.check}")
    end

    def self.get_blessings_path
        @@BLESSING_FILE
    end

end
