# What a book's marking looks like at a glance: its kept highlights grouped by
# Kindle highlighter color, in a stable order, so the library can draw one bar
# per book. Clippings imports carry no color, so unmarked is a normal bucket
# rather than a missing one, and it always sorts last.
module Book::Spectrum
  extend ActiveSupport::Concern

  Band = Struct.new(:color, :count, :share, keyword_init: true) do
    def label = color || "unmarked"
    def percentage = (share * 100).round(2)
  end

  class_methods do
    # One query for a whole page of books, since the library renders a bar each.
    def preload_spectrum(books)
      counts = Highlight.kept.where(book: books).group(:book_id, :color).count

      books.each do |book|
        book.spectrum_counts = counts.filter_map { |(id, color), n| [ color, n ] if id == book.id }.to_h
      end

      books
    end
  end

  attr_writer :spectrum_counts

  def spectrum
    total = spectrum_counts.values.sum
    return [] if total.zero?

    ordered_colors.map do |color|
      count = spectrum_counts[color]
      Band.new(color: color, count: count, share: count.to_f / total)
    end
  end

  private
    def spectrum_counts
      @spectrum_counts ||= highlights.kept.group(:color).count
    end

    def ordered_colors
      present = spectrum_counts.keys
      (Highlight::COLORS & present) + (present.include?(nil) ? [ nil ] : [])
    end
end
