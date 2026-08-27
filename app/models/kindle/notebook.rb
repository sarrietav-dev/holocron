require "net/http"

# Reads highlights from read.amazon.com/notebook using a session cookie you
# paste in from a signed-in browser.
#
# Amazon publishes no API for this and reworks the markup periodically, so the
# parsing lives in Notebook::Page behind fixtures, and two failures are called
# out explicitly rather than being allowed to look like success:
#
#   SessionExpired  the cookie no longer authenticates
#   LayoutChanged   the page loaded but nothing in it parsed
#
# The second matters most. A silent zero-highlight "success" is the failure mode
# to design against, because it looks exactly like having nothing new to sync.
class Kindle::Notebook
  HOST      = "read.amazon.com".freeze
  LIBRARY   = "/notebook".freeze
  USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " \
               "(KHTML, like Gecko) Chrome/124.0 Safari/537.36".freeze

  # Amazon is not expecting a few hundred sequential requests from one session.
  DELAY_BETWEEN_BOOKS = 1.5
  MAX_PAGES_PER_BOOK  = 50

  Error          = Class.new(StandardError)
  SessionExpired = Class.new(Error)
  LayoutChanged  = Class.new(Error)
  RequestFailed  = Class.new(Error)

  def initialize(credential:, delay: DELAY_BETWEEN_BOOKS)
    raise SessionExpired, "No Amazon cookie has been saved yet" if credential.nil?

    @cookie = credential.settings[:cookie].to_s
    @delay  = delay
    raise SessionExpired, "The saved Amazon cookie is empty" if @cookie.blank?
  end

  # Yields [book_attributes, highlight_attributes] per book, matching what
  # Kindle::Clippings yields so Import treats the two identically.
  def each_book
    return enum_for(:each_book) unless block_given?

    books = library
    books.each_with_index do |book, index|
      sleep @delay if index.positive? && @delay.positive?
      yield book.except(:token), highlights_for(book)
    end
  end

  def library
    Kindle::Notebook::Page.new(get(LIBRARY)).books
  end

  # Verifies the cookie without pulling every highlight.
  def test
    library.size
  end

  private
    def highlights_for(book)
      collected = []
      token, limit_state = book[:token], nil

      MAX_PAGES_PER_BOOK.times do
        page = Kindle::Notebook::Page.new(get(annotations_path(book[:asin], token, limit_state)))
        collected.concat(page.highlights)

        token, limit_state = page.next_page_token, page.content_limit_state
        break if token.blank?
        sleep @delay if @delay.positive?
      end

      collected
    end

    def annotations_path(asin, token, limit_state)
      query = { asin: asin, contentLimitState: limit_state.to_s, token: token.to_s }
      "#{LIBRARY}?#{URI.encode_www_form(query)}"
    end

    def get(path)
      response = http.request(request_for(path))

      case response
      when Net::HTTPSuccess    then response.body
      when Net::HTTPRedirection then raise SessionExpired, "Amazon redirected to #{response["location"]} — sign in again and re-copy the cookie"
      when Net::HTTPUnauthorized, Net::HTTPForbidden then raise SessionExpired, "Amazon rejected the session cookie (#{response.code})"
      else raise RequestFailed, "Amazon returned #{response.code} for #{path}"
      end
    end

    def request_for(path)
      Net::HTTP::Get.new(path).tap do |request|
        request["Cookie"]          = @cookie
        request["User-Agent"]      = USER_AGENT
        request["Accept"]          = "text/html,application/xhtml+xml"
        request["Accept-Language"] = "en-US,en;q=0.9"
      end
    end

    def http
      @http ||= Net::HTTP.new(HOST, 443).tap do |connection|
        connection.use_ssl = true
        connection.open_timeout = 15
        connection.read_timeout = 30
      end
    end
end
