class User < ActiveRecord::Base
  def test_sql_sanitize(x)
    self.select("#{sanitize(x)}")
  end

  scope :hits_by_ip, ->(ip,col="*") { select("#{col}").order("id DESC") }

  def arel_exists
    where(User.where(User.arel_table[:object_id].eq(arel_table[:id])).exists)
  end

  def symbol_stuff
    self.where(User.table_name.to_sym)
  end

  scope :sorted_by, ->(field, asc) {
    asc = ['desc', 'asc'].include?(asc) ? asc : 'asc'

    ordering = if field == 'extension'
                 "substring_index(#{table_name}.data_file_name, '.', -1) #{asc}"
               elsif SORTABLE_COLUMNS.include?(field)
                 { field.to_sym => asc.to_sym }
               end
    order(ordering) # should not warn about `asc` interpolation
  }

  def much_arel # None of these should warn
    group_recipient = User.joins(:group).where(User.arel_table[:message_id].eq Email.arel_table[:id])
    group_with_special_property = group_recipient.where(:groups => { :private => false, :special_property => true })
    Email.where(group_recipient.exists.not.or(group_with_special_property.exists))

    User.select('users.id').joins(User.joins(:deal_purchases).join_sources).where(Email.arel_table[:created_at].gt(last_activity)).group('users.id')
    User.where(User.joins(:group).where(User.arel_table[:message_id].eq arel_table[:id]))
  end
end
