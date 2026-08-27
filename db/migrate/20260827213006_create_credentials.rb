class CreateCredentials < ActiveRecord::Migration[8.1]
  def change
    create_table :credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.text :data
      t.datetime :verified_at
      t.datetime :last_used_at
      t.string :last_error

      t.timestamps
    end
    add_index :credentials, [ :user_id, :provider ], unique: true
  end
end
