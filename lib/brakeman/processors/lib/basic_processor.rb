require 'brakeman/processors/lib/processor_helper'
require 'brakeman/util'

class Brakeman::BasicProcessor < Brakeman::SexpProcessor
  include Brakeman::ProcessorHelper
  include Brakeman::Util

  def initialize tracker
    super()
    @tracker = tracker
    @current_template = @current_module = @current_class = @current_method = nil
  end

  def process_default exp
    process_all exp
  end

  def process_safe_call exp
    if self.respond_to? :process_call
      process_call exp
    else
      process_default exp
    end
  end

  def process_safe_attrasgn exp
    if self.respond_to? :process_attrasgn
      process_attrasgn exp
    else
      process_default exp
    end
  end
end
