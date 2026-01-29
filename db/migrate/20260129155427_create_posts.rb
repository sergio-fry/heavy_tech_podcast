class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :posts, :deleted_at
  end
end
