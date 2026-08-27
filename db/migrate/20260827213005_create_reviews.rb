class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.date :scheduled_for, null: false
      t.datetime :sent_at
      t.datetime :completed_at

      t.timestamps
    end
    add_index :reviews, [ :user_id, :scheduled_for ], unique: true

    create_table :review_highlights do |t|
      t.references :review, null: false, foreign_key: true
      t.references :highlight, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :review_highlights, [ :review_id, :highlight_id ], unique: true
  end
end
