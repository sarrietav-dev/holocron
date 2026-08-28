# Parses one page of read.amazon.com/notebook.
#
# Every selector here is a guess about someone else's markup, so each one has a
# fallback and the whole thing refuses to report an empty success: if a page
# looks like a notebook page but nothing parses out of it, that is
# LayoutChanged, not "no highlights".
class Kindle::Notebook::Page
  BOOK_SELECTORS      = [ ".kp-notebook-library-each-book", "[id^='B0'].a-row" ].freeze
  ANNOTATION_SELECTOR = "#kp-notebook-annotations .a-row.a-spacing-base".freeze
  SIGN_IN_SELECTOR    = "#ap_email, form[name='signIn'], #auth-error-message-box".freeze

  COLORS = %w[ yellow blue pink orange ].freeze

  def initialize(html)
    @html = html.to_s
    @doc  = Nokogiri::HTML(@html)
    raise Kindle::Notebook::SessionExpired, "Amazon served the sign-in page" if sign_in_page?
  end

  def books
    nodes = BOOK_SELECTORS.lazy.map { |selector| @doc.css(selector) }.find(&:any?) || []

    if nodes.empty?
      raise Kindle::Notebook::LayoutChanged,
            "No books found on the notebook library page. Amazon's markup has probably changed."
    end

    nodes.filter_map { |node| book_from(node) }
  end

  def highlights
    nodes = @doc.css(ANNOTATION_SELECTOR)

    if nodes.empty?
      return [] if empty_book?

      raise Kindle::Notebook::LayoutChanged,
            "A book page returned no annotations and no empty-library marker. " \
            "Amazon's markup has probably changed."
    end

    nodes.filter_map { |node| highlight_from(node) }
  end

  def next_page_token   = value_of("#kp-notebook-annotations-next-page-start")
  def content_limit_state = value_of("#kp-notebook-content-limit-state")

  private
    def sign_in_page?
      @doc.at_css(SIGN_IN_SELECTOR).present?
    end

    # Amazon says so explicitly when a book genuinely has no highlights; without
    # that marker, zero annotations means the parser has gone stale.
    def empty_book?
      visible_empty_pane? ||
        @doc.at_css("#kp-notebook-no-annotations, .kp-notebook-no-annotations-message").present? ||
        @html.match?(/you have no (?:highlights|notes)/i)
    end

    def visible_empty_pane?
      pane = @doc.at_css("#empty-annotations-pane")
      pane.present? && !pane["class"].to_s.split.include?("aok-hidden")
    end

    def book_from(node)
      asin = node["id"].presence
      title = text_of(node, "h2.kp-notebook-searchable", "h2", ".kp-notebook-searchable")
      return if asin.blank? || title.blank?

      { asin: asin,
        title: title,
        author: author_from(node),
        cover_image_url: node.at_css("img")&.[]("src"),
        token: node.at_css("input[id*='token']")&.[]("value") }
    end

    # Rendered as "By: Yuval Noah Harari", and the label is localized, so take
    # whatever follows the first colon.
    def author_from(node)
      raw = text_of(node, "p.kp-notebook-searchable", "p")
      return if raw.blank?
      raw.split(":", 2).last.to_s.strip.presence
    end

    def highlight_from(node)
      text = text_of(node, "#highlight", ".kp-notebook-highlight")
      return if text.blank?

      header = text_of(node, "#annotationHighlightHeader", ".kp-notebook-metadata")
      location = node.at_css("#kp-annotation-location")&.[]("value")

      { text: text,
        note: text_of(node, "#note", ".kp-notebook-note").presence,
        amazon_id: node["id"].presence,
        color: COLORS.find { |color| header.to_s.downcase.include?(color) },
        location_start: location_from(location, header),
        location_end: location_from(location, header) }
    end

    def location_from(input_value, header)
      return input_value.to_s.tr(",.", "").to_i if input_value.present?
      header.to_s[/(?:location|page)\D{0,3}([\d.,]+)/i, 1]&.tr(",.", "")&.to_i
    end

    def text_of(node, *selectors)
      selectors.each do |selector|
        found = node.at_css(selector)
        return found.text.strip if found && found.text.strip.present?
      end
      nil
    end

    def value_of(selector) = @doc.at_css(selector)&.[]("value").presence
end
