class AddStiToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :type, :string
    add_column :posts, :duration_seconds, :integer
    add_column :posts, :audio_mime_type, :string
    add_index :posts, :type

    reversible do |dir|
      dir.up do
        execute "UPDATE posts SET type = 'Article' WHERE type IS NULL"
      end
    end
  end
end
