#Enable YAML parsing (bad)
ActionController::Base.param_parsers[Mime::YAML] = :yaml

#Disable YAML in XML (good)
ActiveSupport::CoreExtensions::Hash::Conversions::XML_PARSING.delete('symbol') 
ActiveSupport::CoreExtensions::Hash::Conversions::XML_PARSING.delete('yaml') 
