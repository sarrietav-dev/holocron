module BooksHelper
  # One bar per book: its length says how much of that book you marked, its
  # segments say in which colors. The only color in the library, and all of it
  # comes from the reader's own highlighting.
  def spectrum_bar(book, relative_to:)
    bands = book.spectrum
    return if bands.empty?

    width = [ book.highlights_count.to_f / [ relative_to, 1 ].max * 100, 4 ].max

    tag.div class: "spectrum-track", role: "img", aria: { label: spectrum_description(bands) } do
      tag.div class: "spectrum", style: "width: #{width.round(2)}%" do
        safe_join(bands.map { |band|
          tag.span class: "spectrum__band spectrum__band--#{band.label}", style: "width: #{band.percentage}%"
        })
      end
    end
  end

  private
    def spectrum_description(bands)
      "Highlights by color: " + bands.map { |band| "#{band.count} #{band.label}" }.to_sentence
    end
end
