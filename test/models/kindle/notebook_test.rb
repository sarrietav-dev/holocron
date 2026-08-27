require "test_helper"

class Kindle::NotebookTest < ActiveSupport::TestCase
  setup do
    @credential = users(:one).credentials.create!(provider: Credential::AMAZON, settings: { cookie: "session-id=abc" })
  end

  # Stands in for the network: maps a request path to a fixture body.
  class StubbedNotebook < Kindle::Notebook
    attr_reader :requested

    def initialize(pages:, **options)
      super(**options)
      @pages, @requested = pages, []
    end

    private
      def get(path)
        @requested << path
        body = @pages.find { |matcher, _| path.include?(matcher) }&.last
        raise "no stub for #{path}" unless body
        body
      end
  end

  def fixture(name) = file_fixture("#{name}.html").read

  def notebook(pages)
    StubbedNotebook.new(credential: @credential, delay: 0, pages: pages)
  end

  test "requires a credential" do
    error = assert_raises(Kindle::Notebook::SessionExpired) { Kindle::Notebook.new(credential: nil) }
    assert_match(/No Amazon cookie/, error.message)
  end

  test "requires the credential to actually hold a cookie" do
    empty = users(:one).credentials.create!(provider: "blank", settings: { cookie: "" })
    assert_raises(Kindle::Notebook::SessionExpired) { Kindle::Notebook.new(credential: empty) }
  end

  test "yields each book with its highlights" do
    client = notebook([ [ "asin=", fixture("notebook_book") ], [ "/notebook", fixture("notebook_library") ] ])
    books = client.each_book.to_a

    assert_equal 2, books.size

    attributes, highlights = books.first
    assert_equal "Sapiens: A Brief History of Humankind", attributes[:title]
    assert_equal "B00ICN066A", attributes[:asin]
    assert_equal 2, highlights.size
  end

  test "does not leak the pagination token into the book attributes" do
    client = notebook([ [ "asin=", fixture("notebook_book") ], [ "/notebook", fixture("notebook_library") ] ])
    attributes, _ = client.each_book.first

    assert_not attributes.key?(:token)
  end

  test "follows pagination until the token runs out" do
    library    = fixture("notebook_library")
    first_page = fixture("notebook_book_page_one")
    last_page  = fixture("notebook_book")
    calls = 0

    client = notebook([ [ "/notebook", library ] ])
    client.define_singleton_method(:get) do |path|
      next library unless path.include?("asin=")
      calls += 1
      calls == 1 ? first_page : last_page
    end

    _, highlights = client.each_book.first

    assert_equal 3, highlights.size, "should collect the first page and the last"
    assert_equal "First page highlight.", highlights.first[:text]
  end

  test "stops paginating rather than looping forever" do
    library  = fixture("notebook_library")
    endless  = fixture("notebook_book_page_one")

    client = notebook([ [ "/notebook", library ] ])
    client.define_singleton_method(:get) do |path|
      path.include?("asin=") ? endless : library
    end

    _, highlights = client.each_book.first

    assert_equal Kindle::Notebook::MAX_PAGES_PER_BOOK, highlights.size
  end

  test "test reports how many books the cookie can see" do
    client = notebook([ [ "/notebook", fixture("notebook_library") ] ])
    assert_equal 2, client.test
  end

  test "surfaces an expired session rather than an empty library" do
    client = notebook([ [ "/notebook", fixture("notebook_signed_out") ] ])
    assert_raises(Kindle::Notebook::SessionExpired) { client.test }
  end
end
