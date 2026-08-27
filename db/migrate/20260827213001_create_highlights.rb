class CreateHighlights < ActiveRecord::Migration[8.1]
  def change
    create_table :highlights do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.text :text, null: false
      t.text :note
      t.string :text_hash, null: false
      t.integer :location_start
      t.integer :location_end
      t.string :page
      t.string :chapter
      t.string :color
      t.string :amazon_id
      t.datetime :highlighted_at
      t.boolean :favorite, null: false, default: false
      t.datetime :discarded_at
      t.integer :reviews_count, null: false, default: 0
      t.datetime :last_reviewed_at

      t.timestamps
    end

    # The one dedupe guarantee: the same highlight arriving from My Clippings.txt
    # and from the Kindle notebook hashes identically, so it merges rather than duplicates.
    add_index :highlights, [ :book_id, :text_hash ], unique: true
    add_index :highlights, [ :user_id, :discarded_at, :last_reviewed_at ], name: "index_highlights_on_review_candidates"
    add_index :highlights, [ :user_id, :favorite ]
  end
end
