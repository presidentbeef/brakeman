Brakeman.load_brakeman_dependency 'erubis'

require 'brakeman/parsers/erubis_patch'

#Erubis processor which ignores any output which is plain text.
class Brakeman::ScannerErubis < Erubis::Eruby
  include Erubis::NoTextEnhancer
  include Brakeman::ErubisPatch
end
