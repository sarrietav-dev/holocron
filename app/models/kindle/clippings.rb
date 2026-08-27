# Parses a My Clippings.txt straight off the Kindle.
#
#   Sapiens: A Brief History of Humankind (Yuval Noah Harari)
#   - Your Highlight on page 12 | Location 145-146 | Added on Monday, 1 January 2024 10:23:45
#
#   History is something very few people have been doing.
#   ==========
#
# The file is append-only and never deduplicated by the device, so the same
# highlight appears again every time it is edited. Dedupe happens downstream,
# on text_hash.
class Kindle::Clippings
  SEPARATOR = /^\s*={5,}\s*$/
  CLIPPING_LIMIT = /\A<You have reached the clipping limit/i

  # The device writes "Location", "Loc." or a localized equivalent; matching on
  # the digits after the last "|"-delimited label is more robust than matching
  # the label itself.
  LOCATION  = /(?:location|loc\.?|position|pos\.?)\D{0,3}(\d[\d.,]*)(?:\s*[-–]\s*(\d[\d.,]*))?/i
  PAGE      = /page\s+([\w.,-]+)/i
  ADDED     = /added on\s+(.+?)\s*\z/i

  HIGHLIGHT = /highlight|surlignement|markierung|subrayado|evidenziazione|destaque|マーカー|标注/i
  NOTE      = /\bnote\b|notiz|nota|メモ|笔记/i
  BOOKMARK  = /bookmark|lesezeichen|marcador|signet|segnalibro|ブックマーク|书签/i

  Entry = Struct.new(:kind, :title, :author, :page, :location_start, :location_end, :added_at, :text, :note, keyword_init: true)

  def initialize(text)
    @text = normalize(text)
  end

  def each_book
    return enum_for(:each_book) unless block_given?

    entries.group_by { |entry| [ entry.title, entry.author ] }.each do |(title, author), grouped|
      highlights, notes = grouped.partition { |entry| entry.kind == :highlight }
      next if highlights.empty?

      yield({ title: title, author: author }, attach(notes, to: highlights))
    end
  end

  def entries
    @entries ||= @text.split(SEPARATOR).filter_map { |record| parse(record) }
  end

  private
    def normalize(text)
      text.to_s
          .dup
          .force_encoding(Encoding::UTF_8)
          .scrub("")
          .delete_prefix("﻿")
          .gsub("\r\n", "\n")
    end

    def parse(record)
      lines = record.split("\n").map(&:strip)
      lines.shift while lines.first == ""
      title_line, meta_line, *body = lines
      return if title_line.blank? || meta_line.blank?

      kind = kind_of(meta_line)
      return unless kind

      text = body.join("\n").strip
      return if text.blank? || text.match?(CLIPPING_LIMIT)

      title, author = split_title(title_line)
      locations = meta_line[LOCATION, 1] && meta_line.match(LOCATION)

      Entry.new(
        kind: kind, title: title, author: author,
        page: meta_line[PAGE, 1],
        location_start: to_i(locations && locations[1]),
        location_end: to_i(locations && locations[2]) || to_i(locations && locations[1]),
        added_at: parse_time(meta_line[ADDED, 1]),
        text: text
      )
    end

    # Bookmarks carry no text and are dropped; the order matters because
    # "Your Note" and "Your Highlight" both contain locale words that overlap.
    def kind_of(meta_line)
      return if meta_line.match?(BOOKMARK)
      return :highlight if meta_line.match?(HIGHLIGHT)
      return :note if meta_line.match?(NOTE)
      nil
    end

    # The author is the last parenthesised group on the line, because both the
    # title and the author itself may contain parentheses and commas:
    #   "Thinking, Fast and Slow (Kahneman, Daniel)"
    def split_title(line)
      return [ line, nil ] unless line.end_with?(")")

      depth = 0
      index = line.length - 1
      while index >= 0
        depth += 1 if line[index] == ")"
        depth -= 1 if line[index] == "("
        break if depth.zero?
        index -= 1
      end
      return [ line, nil ] if index <= 0

      [ line[0...index].strip, line[(index + 1)...-1].strip.presence ]
    end

    def attach(notes, to:)
      highlights = to.sort_by { |entry| entry.location_start || 0 }

      notes.each do |note|
        target = enclosing(highlights, note) || preceding(highlights, note)
        target.note ||= note.text if target
      end

      highlights.map { |entry| to_attributes(entry) }
    end

    def enclosing(highlights, note)
      return if note.location_start.nil?
      highlights.find do |highlight|
        highlight.location_start && highlight.location_end &&
          note.location_start.between?(highlight.location_start, highlight.location_end)
      end
    end

    def preceding(highlights, note)
      return highlights.last if note.location_start.nil?
      highlights.select { |h| (h.location_start || 0) <= note.location_start }.last
    end

    def to_attributes(entry)
      {
        text: entry.text,
        note: entry.note,
        page: entry.page,
        location_start: entry.location_start,
        location_end: entry.location_end,
        highlighted_at: entry.added_at
      }.compact
    end

    def to_i(value) = value && value.tr(".,", "").to_i

    def parse_time(value)
      return if value.blank?
      Time.zone.parse(value.sub(/\A\p{Alpha}+,?\s*/, ""))
    rescue ArgumentError
      nil
    end
end
