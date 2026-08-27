# Renders one book as an Obsidian note.
#
# Everything below MARKER is yours: it is read back off disk and re-appended
# untouched on every sync. That marker is the whole "your edits survive"
# contract, so nothing in here may write below it.
class Obsidian::Note
  MARKER = "<!-- holocron:end -->".freeze

  # Reserved on Windows and in Obsidian itself, plus the ones that would create
  # unintended folders or block references.
  UNSAFE_IN_FILENAME = %r{[/\\:*?"<>|#^\[\]]}
  MAX_FILENAME = 120

  def initialize(book)
    @book = book
  end

  def filename = "#{sanitized_title}.md"

  # Existing content is whatever is on disk, or nil for a new note.
  def render(existing = nil)
    [ generated, preserved(existing) ].compact.join("\n")
  end

  private
    attr_reader :book

    def generated
      <<~MARKDOWN
        #{front_matter}

        # #{book.title}

        #{highlight_lines}

        #{MARKER}
      MARKDOWN
    end

    # JSON string escaping is valid YAML string escaping, which saves hand-rolling
    # quoting for titles containing colons and quotation marks.
    def front_matter
      fields = {
        "title" => book.title,
        "author" => book.author,
        "asin" => book.asin,
        "source" => "holocron",
        "highlights" => book.highlights_count,
        "synced" => Time.current.utc.iso8601
      }.compact

      [ "---", *fields.map { |key, value| "#{key}: #{value.is_a?(Integer) ? value : value.to_s.to_json}" }, "---" ].join("\n")
    end

    def highlight_lines
      highlights = book.highlights.kept.in_reading_order.includes(:tags)
      return "_No highlights yet._" if highlights.empty?

      [ "## Highlights", "", *highlights.map { |highlight| entry_for(highlight) } ].join("\n")
    end

    def entry_for(highlight)
      lines = [ "- #{one_line(highlight.text)}#{reference(highlight)} ^#{highlight.block_id}" ]
      lines << "    - **Note:** #{one_line(highlight.note)}" if highlight.note.present?
      lines << "    - #{highlight.tag_list.map { |tag| "##{tag.tr(" ", "-")}" }.join(" ")}" if highlight.tags.any?
      lines << ""
      lines.join("\n")
    end

    # A highlight containing a newline would otherwise break out of its list item.
    def one_line(text) = text.to_s.gsub(/\s*\n\s*/, " ").strip

    def reference(highlight)
      return "" if highlight.location.blank?

      label = "Location #{highlight.location}"
      highlight.kindle_url ? " — [#{label}](#{highlight.kindle_url})" : " — #{label}"
    end

    def preserved(existing)
      return if existing.blank?

      index = existing.index(MARKER)
      return if index.nil?

      tail = existing[(index + MARKER.length)..].to_s
      tail.strip.empty? ? nil : tail.sub(/\A\n+/, "\n")
    end

    def sanitized_title
      cleaned = book.title.to_s.gsub(UNSAFE_IN_FILENAME, " ").squish.delete_suffix(".")
      cleaned = "Untitled" if cleaned.blank?
      cleaned = cleaned.truncate(MAX_FILENAME, omission: "")

      # Two different books can still sanitize to the same name; the ASIN keeps
      # them apart, and the id is the last resort.
      book.asin.present? ? "#{cleaned} (#{book.asin})" : "#{cleaned} (#{book.id})"
    end
end
