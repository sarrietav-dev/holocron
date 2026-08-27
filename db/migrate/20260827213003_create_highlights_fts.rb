class CreateHighlightsFts < ActiveRecord::Migration[8.1]
  def change
    # rowid is the highlight id, so search joins straight back to the table.
    #
    # Kept in sync from Highlight::Searchable, not from SQL triggers: Rails does
    # not dump triggers to schema.rb, so a trigger-backed index would vanish on
    # db:test:prepare and every search test would pass against an empty table.
    create_virtual_table :highlights_fts, :fts5, [
      "text",
      "note",
      "book_title",
      "book_author",
      "tokenize='porter unicode61'"
    ]
  end
end
