class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :display_name
      t.string :user_name
      t.string :signature
      t.string :profile
      t.string :password
      t.boolean :admin

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
