module HighlightsHelper
  # A passage is drawn as a highlighter stroke behind the words themselves, so
  # every paragraph needs an inline element to carry the wash. Highlights with
  # no color (every My Clippings.txt import) get the unmarked treatment.
  def passage(highlight)
    tag.blockquote class: [ "passage", "passage--#{highlight.color || 'unmarked'}" ] do
      safe_join(highlight.text.to_s.split(/\n{2,}/).map { |paragraph|
        tag.p(tag.span(paragraph.strip, class: "stroke"))
      })
    end
  end

  # The catalog card: what the system knows about where this passage came from.
  # Each fact is omitted rather than faked when it is missing. Facts and
  # separators are separate elements so the margin layout can stack the facts
  # and drop the separators.
  def provenance(highlight)
    facts = []
    facts << "Loc #{highlight.location}" if highlight.location.present?
    facts << "Ch #{highlight.chapter}" if highlight.chapter.present?
    facts << "Marked #{highlight.highlighted_at.year}" if highlight.highlighted_at.present?
    facts << "Seen #{highlight.reviews_count}×" if highlight.reviews_count.positive?
    return if facts.empty?

    tag.p class: "provenance" do
      safe_join(facts.map { |fact| tag.span(fact, class: "fact") },
                tag.span("·", class: "sep", aria: { hidden: true }))
    end
  end
end
