class Import < ApplicationRecord
  include Runnable

  belongs_to :user
  delegated_type :source, types: %w[ Kindle::ClippingsImport Kindle::NotebookImport ], dependent: :destroy

  after_update_commit -> { broadcast_replace_later_to user, :imports }

  scope :newest_first, -> { order(created_at: :desc) }

  # Each source knows how to enumerate books and highlights; nothing here
  # branches on which one it is.
  def run
    start!
    source.each_book(self) { |book_attributes, highlights| absorb(book_attributes, highlights) }
    complete!
  rescue => error
    fail!(error)
    raise
  end

  def absorb(book_attributes, highlights)
    book = user.books.for(**book_attributes)
    tally(:books_created) if book.previously_new_record?

    highlights.each do |attributes|
      highlight = book.highlights.record(**attributes)
      tally(highlight.previously_new_record? ? :highlights_created : :highlights_updated)
    end

    book.touch(:last_highlighted_at) if highlights.any?
  end
end
