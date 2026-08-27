# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_27_213005) do
  create_table "books", force: :cascade do |t|
    t.datetime "archived_at"
    t.string "asin"
    t.string "author"
    t.string "cover_image_url"
    t.datetime "created_at", null: false
    t.string "dedupe_key", null: false
    t.integer "highlights_count", default: 0, null: false
    t.datetime "last_highlighted_at"
    t.datetime "obsidian_synced_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "archived_at"], name: "index_books_on_user_id_and_archived_at"
    t.index ["user_id", "asin"], name: "index_books_on_user_id_and_asin", unique: true, where: "asin IS NOT NULL"
    t.index ["user_id", "dedupe_key"], name: "index_books_on_user_id_and_dedupe_key", unique: true
    t.index ["user_id"], name: "index_books_on_user_id"
  end

  create_table "highlights", force: :cascade do |t|
    t.string "amazon_id"
    t.integer "book_id", null: false
    t.string "chapter"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.boolean "favorite", default: false, null: false
    t.datetime "highlighted_at"
    t.datetime "last_reviewed_at"
    t.integer "location_end"
    t.integer "location_start"
    t.text "note"
    t.string "page"
    t.integer "reviews_count", default: 0, null: false
    t.text "text", null: false
    t.string "text_hash", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["book_id", "text_hash"], name: "index_highlights_on_book_id_and_text_hash", unique: true
    t.index ["book_id"], name: "index_highlights_on_book_id"
    t.index ["user_id", "discarded_at", "last_reviewed_at"], name: "index_highlights_on_review_candidates"
    t.index ["user_id", "favorite"], name: "index_highlights_on_user_id_and_favorite"
    t.index ["user_id"], name: "index_highlights_on_user_id"
  end

  create_table "review_highlights", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "highlight_id", null: false
    t.integer "position", default: 0, null: false
    t.integer "review_id", null: false
    t.datetime "updated_at", null: false
    t.index ["highlight_id"], name: "index_review_highlights_on_highlight_id"
    t.index ["review_id", "highlight_id"], name: "index_review_highlights_on_review_id_and_highlight_id", unique: true
    t.index ["review_id"], name: "index_review_highlights_on_review_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.date "scheduled_for", null: false
    t.datetime "sent_at"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "scheduled_for"], name: "index_reviews_on_user_id_and_scheduled_for", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "tag_id", null: false
    t.integer "taggable_id", null: false
    t.string "taggable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id", "taggable_type", "taggable_id"], name: "index_taggings_uniqueness", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "slug"], name: "index_tags_on_user_id_and_slug", unique: true
    t.index ["user_id"], name: "index_tags_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "daily_review_enabled", default: true, null: false
    t.integer "daily_review_hour", default: 8, null: false
    t.integer "daily_review_size", default: 5, null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "time_zone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "books", "users"
  add_foreign_key "highlights", "books"
  add_foreign_key "highlights", "users"
  add_foreign_key "review_highlights", "highlights"
  add_foreign_key "review_highlights", "reviews"
  add_foreign_key "reviews", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "taggings", "tags"
  add_foreign_key "tags", "users"

  # Virtual tables defined in this database.
  # Note that virtual tables may not work with other database engines. Be careful if changing database.
  create_virtual_table "highlights_fts", "fts5", ["text", "note", "book_title", "book_author", "tokenize='porter unicode61'"]
end
