class CreateBooks < ActiveRecord::Migration[8.1]
  def change
    create_table :books do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.string :author
      t.string :asin
      t.string :cover_image_url
      t.string :dedupe_key, null: false
      t.integer :highlights_count, null: false, default: 0
      t.datetime :last_highlighted_at
      t.datetime :obsidian_synced_at
      t.datetime :archived_at

      t.timestamps
    end

    add_index :books, [ :user_id, :dedupe_key ], unique: true
    add_index :books, [ :user_id, :asin ], unique: true, where: "asin IS NOT NULL"
    add_index :books, [ :user_id, :archived_at ]
  end
end
