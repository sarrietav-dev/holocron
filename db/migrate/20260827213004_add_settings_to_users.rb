class AddSettingsToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.string  :time_zone, null: false, default: "UTC"
      t.boolean :daily_review_enabled, null: false, default: true
      t.integer :daily_review_hour, null: false, default: 8
      t.integer :daily_review_size, null: false, default: 5
    end
  end
end
