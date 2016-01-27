module ActiveRecord
  module NestedAttributes
    private

    def reject_new_record?(association_name, attributes)
      will_be_destroyed?(association_name, attributes) || call_reject_if(association_name, attributes)
    end

    def call_reject_if(association_name, attributes)
      return false if will_be_destroyed?(association_name, attributes)

      case callback = self.nested_attributes_options[association_name][:reject_if]
      when Symbol
        method(callback).arity == 0 ? send(callback) : send(callback, attributes)
      when Proc
        callback.call(attributes)
      end
    end

    def will_be_destroyed?(association_name, attributes)
      allow_destroy?(association_name) && has_destroy_flag?(attributes)
    end

    def allow_destroy?(association_name)
      self.nested_attributes_options[association_name][:allow_destroy]
    end
  end
end
