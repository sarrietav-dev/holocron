require "test_helper"

class HighlightTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @book = @user.books.for(title: "Sapiens", author: "Yuval Noah Harari", asin: "B00ICN066A")
  end

  test "treats whitespace, case and a trailing ellipsis as the same highlight" do
    @book.highlights.record(text: "  History  is   something people do…  ")
    @book.highlights.record(text: "History is something people do.")

    assert_equal 1, @book.highlights.count
  end

  test "enriches an existing highlight with what a later source knows" do
    @book.highlights.record(text: "A highlight", location_start: 145)
    highlight = @book.highlights.record(text: "A highlight", color: "yellow", amazon_id: "AB12")

    assert_equal 145, highlight.location_start
    assert_equal "yellow", highlight.color
    assert_equal "AB12", highlight.amazon_id
  end

  test "never overwrites a note you typed" do
    highlight = @book.highlights.record(text: "A highlight")
    highlight.update!(note: "my own thinking")

    @book.highlights.record(text: "A highlight", note: "a note from Amazon")

    assert_equal "my own thinking", highlight.reload.note
  end

  test "accepts a note when there is not one already" do
    @book.highlights.record(text: "A highlight")
    highlight = @book.highlights.record(text: "A highlight", note: "from Amazon")

    assert_equal "from Amazon", highlight.note
  end

  test "gives a stable block id so Obsidian references keep resolving" do
    first  = @book.highlights.record(text: "A highlight")
    id     = first.block_id
    second = @book.highlights.record(text: "A highlight", color: "blue")

    assert_equal id, second.block_id
    assert_match(/\Ahl-[0-9a-f]{8}\z/, id)
  end

  test "builds a kindle deep link only when it has both an ASIN and a location" do
    with_location = @book.highlights.record(text: "Located", location_start: 145)
    without       = @book.highlights.record(text: "Unlocated")

    assert_equal "kindle://book?action=open&asin=B00ICN066A&location=145", with_location.kindle_url
    assert_nil without.kindle_url
  end

  test "formats a single location without a range" do
    highlight = @book.highlights.record(text: "One spot", location_start: 145, location_end: 145)
    assert_equal "145", highlight.location
  end

  test "the same text in two books is two highlights" do
    other = @user.books.for(title: "Another Book", author: "Someone")
    @book.highlights.record(text: "Shared sentence")
    other.highlights.record(text: "Shared sentence")

    assert_equal 2, @user.highlights.count
  end
end
