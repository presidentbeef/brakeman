require 'i18n' 

# Override exception handler to more carefully html-escape missing-key results. 
class HtmlSafeI18nExceptionHandler 
  Missing = I18n.const_defined?(:MissingTranslation) ? I18n::MissingTranslation : I18n::MissingTranslationData 

  def initialize(original_exception_handler) 
    @original_exception_handler = original_exception_handler 
  end 

  def call(exception, locale, key, options) 
    if exception.is_a?(Missing) && options[:rescue_format] == :html 
      keys = exception.keys.map { |k| Rack::Utils.escape_html k } 
      key = keys.last.to_s.gsub('_', ' ').gsub(/\b('?[a-z])/) { $1.capitalize } 
      %(<span class="translation_missing" title="translation missing: #{keys.join('.')}">#{key}</span>) 
    else 
      @original_exception_handler.call(exception, locale, key, options) 
    end 
  end 
end 
