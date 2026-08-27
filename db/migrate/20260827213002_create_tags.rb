class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end
    add_index :tags, [ :user_id, :slug ], unique: true

    create_table :taggings do |t|
      t.references :tag, null: false, foreign_key: true
      t.references :taggable, null: false, polymorphic: true

      t.timestamps
    end
    add_index :taggings, [ :tag_id, :taggable_type, :taggable_id ], unique: true, name: "index_taggings_uniqueness"
  end
end
