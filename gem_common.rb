module Brakeman
  module GemDependencies
    def self.dev_dependencies spec
      spec.add_development_dependency "minitest"
      spec.add_development_dependency "minitest-ci"
      spec.add_development_dependency "simplecov"
    end

    def self.base_dependencies spec
      spec.add_dependency "ruby_parser", "~>3.13"
      spec.add_dependency "ruby_parser-legacy", "~>1.0"
      spec.add_dependency "sexp_processor", "~> 4.7"
      spec.add_dependency "ruby2ruby", "~>2.4.0"
      spec.add_dependency "safe_yaml", ">= 1.0"
    end

    def self.extended_dependencies spec
      spec.add_dependency "terminal-table", "~>1.4"
      spec.add_dependency "highline", "~>2.0"
      spec.add_dependency "erubis", "~>2.6"
      spec.add_dependency "haml", ">=3.0", "<5.0"
      spec.add_dependency "slim", ">=1.3.6", "<=4.0.1"
    end
  end
end
