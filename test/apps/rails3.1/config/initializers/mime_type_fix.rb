require 'action_dispatch/http/mime_type' 

Mime.const_set :LOOKUP, Hash.new { |h,k| 
    Mime::Type.new(k) unless k.blank? 
}
