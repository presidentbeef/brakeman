class Email < ActiveRecord::Base
  attr_accessible :email

  belongs_to :user

  EMAIL_REGEX = /^[a-z0-9]+@[a-z0-9]+\.[a-z]+$/

  validates_format_of :email, with: EMAIL_REGEX

  scope :assigned_to_user, ->(user) {
    task_table = User.table_name

    joins("INNER JOIN #{task_table}
          ON  #{task_table}.user_id = #{user.id}
          AND (#{task_table}.type_id = #{table_name}.type_id)
          AND (#{task_table}.manager_id = #{table_name}.manager_id)
          ")
  }
end
