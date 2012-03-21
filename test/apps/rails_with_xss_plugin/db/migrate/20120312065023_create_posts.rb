class CreatePosts < ActiveRecord::Migration
  def self.up
    create_table :posts do |t|
      t.integer :user_id
      t.string :title
      t.string :body
      t.integer :in_reply_to

      t.timestamps
    end
  end

  def self.down
    drop_table :posts
  end
end
