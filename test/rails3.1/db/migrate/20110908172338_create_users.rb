class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :bio
      t.string :password
      t.string :email
      t.string :role

      t.timestamps
    end
  end
end
