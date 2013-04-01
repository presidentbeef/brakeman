module ControllerFilter
  # Basically copied from the wilds
  def self.included somewhere
    somewhere.class_eval do
      before_filter do
        do_something
      end
    end
  end
end
