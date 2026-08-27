require "test_helper"

class Kindle::ClippingsTest < ActiveSupport::TestCase
  setup do
    @books = Kindle::Clippings.new(file_fixture("my_clippings.txt").read).each_book.to_a
  end

  def book(title) = @books.find { |attributes, _| attributes[:title] == title }

  test "reads a file with a BOM and CRLF endings" do
    assert_equal 3, @books.size
  end

  test "separates a title from its author" do
    attributes, _ = book("Sapiens: A Brief History of Humankind")
    assert_equal "Yuval Noah Harari", attributes[:author]
  end

  test "keeps an author containing a comma with the author, not the title" do
    attributes, _ = book("Thinking, Fast and Slow")
    assert_equal "Kahneman, Daniel", attributes[:author]
  end

  test "handles a title with no author at all" do
    attributes, highlights = book("A Book With No Author")
    assert_nil attributes[:author]
    assert_equal 1, highlights.size
  end

  test "attaches a note to the highlight whose range encloses it" do
    _, highlights = book("Sapiens: A Brief History of Humankind")
    assert_equal "Compare with Diamond's argument", highlights.first[:note]
  end

  test "skips bookmarks, which carry no text" do
    _, highlights = book("Sapiens: A Brief History of Humankind")
    assert_empty highlights.select { |h| h[:text].blank? }
  end

  test "skips the clipping limit placeholder" do
    _, highlights = book("Thinking, Fast and Slow")

    assert_equal 1, highlights.size
    assert_no_match(/clipping limit/i, highlights.first[:text])
  end

  test "reads a location range with no page number" do
    _, highlights = book("Thinking, Fast and Slow")

    assert_equal 1180, highlights.first[:location_start]
    assert_equal 1181, highlights.first[:location_end]
    assert_nil highlights.first[:page]
  end

  test "reads page, location and timestamp together" do
    _, highlights = book("Sapiens: A Brief History of Humankind")
    highlight = highlights.first

    assert_equal "12", highlight[:page]
    assert_equal 145, highlight[:location_start]
    assert_equal Time.utc(2024, 1, 1, 10, 23, 45), highlight[:highlighted_at]
  end

  test "returns nothing for an empty or unparseable file" do
    assert_empty Kindle::Clippings.new("").each_book.to_a
    assert_empty Kindle::Clippings.new("not a clippings file at all").each_book.to_a
  end

  test "strips thousands separators from large locations" do
    clipping = <<~TXT
      Big Book (An Author)
      - Your Highlight on page 400 | Location 12,345-12,350 | Added on Monday, 1 January 2024 10:00:00

      A late highlight.
      ==========
    TXT
    _, highlights = Kindle::Clippings.new(clipping).each_book.to_a.first

    assert_equal 12345, highlights.first[:location_start]
    assert_equal 12350, highlights.first[:location_end]
  end
end
