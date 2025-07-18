class Group < ApplicationRecord
  enum status: { start: 0, stop: 2, in_process: 3 }

  def use_enum
    # No warning
    where("thing IN #{Group.statuses.values_at(:start, :stop).join(',')}")
  end
end
