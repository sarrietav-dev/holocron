class CreateImports < ActiveRecord::Migration[8.1]
  def change
    create_table :imports do |t|
      t.references :user, null: false, foreign_key: true
      t.references :source, null: false, polymorphic: true
      t.string :status, null: false, default: "pending"
      t.integer :books_created, null: false, default: 0
      t.integer :highlights_created, null: false, default: 0
      t.integer :highlights_updated, null: false, default: 0
      t.text :error_message
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end
    add_index :imports, [ :user_id, :created_at ]

    # The raw upload is kept so a parser fix can be replayed against it.
    create_table :kindle_clippings_imports do |t|
      t.text :raw_text, null: false
      t.string :filename
      t.timestamps
    end

    create_table :kindle_notebook_imports do |t|
      t.integer :books_seen, null: false, default: 0
      t.timestamps
    end
  end
end
