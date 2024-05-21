module Brakeman
  module GemDependencies
    def self.dev_dependencies spec
      spec.add_development_dependency "minitest"
      spec.add_development_dependency "minitest-ci"
      spec.add_development_dependency "simplecov"
      spec.add_development_dependency "simplecov-html", "=0.10.2"
    end

    def self.base_dependencies spec
      spec.add_dependency "parallel", "~>1.20"
      spec.add_dependency "ruby_parser", "~>3.20.2"
      spec.add_dependency "sexp_processor", "~> 4.7"
      spec.add_dependency "ruby2ruby", "~>2.4.0"
      spec.add_dependency "racc"
    end

    def self.extended_dependencies spec
      spec.add_dependency "terminal-table", "~>1.4"
      spec.add_dependency "highline", "~>3.0"
      spec.add_dependency "erubis", "~>2.6"
      spec.add_dependency "haml", "~>5.1"
      spec.add_dependency "slim", ">=1.3.6", "<=4.1"
      spec.add_dependency "rexml", "~>3.0"
    end
  end
end
