class EnumRepro < ApplicationRecord
  enum :status, { start: 0, stop: 1, in_process: 2 }

  def use_enum
    # Should NOT warn: values come only from the enum's own defined value set,
    # not from user input. This is the new (Rails 7.1+) positional-args enum syntax.
    where("thing IN (#{EnumRepro.statuses[:start]})")
  end
end

class EnumReproOldStyle < ApplicationRecord
  enum kind: { foo: 0, bar: 1 }

  def use_enum_old
    # Should also NOT warn: pre-Rails-7.1 single-hash enum syntax (regression check).
    where("thing IN (#{EnumReproOldStyle.kinds[:foo]})")
  end
end
