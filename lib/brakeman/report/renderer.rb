class Brakeman::Report
  class Renderer
    def initialize(template_file, hash = {})
      hash[:locals] ||= {}
      hash[:locals].each do |key, value|
        singleton_class.send(:define_method, key) { value }
      end

      singleton_class.send(:define_method, 'template_file') { template_file }

      singleton_class.send(:define_method, 'template') {
        File.read(File.expand_path("templates/#{template_file}.html.erb", File.dirname(__FILE__)))
      }
    end

    def render
      ERB.new(template).result(binding)
    end
  end
end