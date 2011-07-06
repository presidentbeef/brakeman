require 'digest/md5'


module Blessing

    @@WHOLE_LINE_COMMENTS = {:ruby => /^(?:\s*)#.+$/,
                             :haml => /^(?:\s*)<!--.+-->$/,
                             :erb => /^(?:\s*)<!--.+-->$/}
    @@HASH_IN_COMMENT = /(?:^|[^\w]|\s+)\w{32}(?:\s+|[^\w]|$)/

    @@blessings = Hash.new

    def self.is_blessed?(result)
        hash = self.hash_result result
        puts "checking #{hash}"
        @@blessings[hash]
    end

    def self.hash_result(result)
        Digest::MD5.hexdigest("#{result.class}\n#{result.code.to_s}\n#{result.check}")
    end

    def self.add_blessing(blessing_hash)
        @@blessings[blessing_hash] = true
    end

    def self.parse_string_for_blessings string, language=:ruby
      comments = string.scan @@WHOLE_LINE_COMMENTS[language]
      comments.each do |comment|
        comment.scan(@@HASH_IN_COMMENT) do |blessing_hash|
          Blessing.add_blessing blessing_hash.strip
        end
      end
    end

end
