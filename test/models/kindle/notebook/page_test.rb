require "test_helper"

class Kindle::Notebook::PageTest < ActiveSupport::TestCase
  def page(name) = Kindle::Notebook::Page.new(file_fixture("#{name}.html").read)

  test "reads the library" do
    books = page("notebook_library").books

    assert_equal 2, books.size
    assert_equal "B00ICN066A", books.first[:asin]
    assert_equal "Sapiens: A Brief History of Humankind", books.first[:title]
    assert_equal "Yuval Noah Harari", books.first[:author]
    assert_match %r{sapiens}, books.first[:cover_image_url]
    assert_equal "TOKEN-SAPIENS", books.first[:token]
  end

  test "keeps an author containing a comma out of the title" do
    assert_equal "Kahneman, Daniel", page("notebook_library").books.second[:author]
  end

  test "reads highlights, notes, colours and locations" do
    highlights = page("notebook_book").highlights

    assert_equal 2, highlights.size
    assert_equal "History is something very few people have been doing.", highlights.first[:text]
    assert_equal "Compare with Diamond's argument", highlights.first[:note]
    assert_equal "yellow", highlights.first[:color]
    assert_equal 1234, highlights.first[:location_start]
    assert_equal "QUJDRDEyMw", highlights.first[:amazon_id]
  end

  test "leaves the note nil when there is not one" do
    assert_nil page("notebook_book").highlights.second[:note]
    assert_equal "blue", page("notebook_book").highlights.second[:color]
  end

  test "reports the pagination token when there are more pages" do
    assert_equal "NEXT-TOKEN", page("notebook_book_page_one").next_page_token
    assert_equal "LIMIT-STATE-2", page("notebook_book_page_one").content_limit_state
  end

  test "reports no token on the last page" do
    assert_nil page("notebook_book").next_page_token
  end

  test "a book with genuinely no highlights is not an error" do
    assert_empty page("notebook_empty_book").highlights
    assert_empty page("notebook_empty_book_current").highlights
  end

  test "parses annotation rows from an AJAX fragment without the container div" do
    highlights = page("notebook_annotation_ajax_fragment").highlights

    assert_equal 3, highlights.size
    assert highlights.first[:text].include?("Gandalf")
    assert highlights.first[:amazon_id].present?
  end

  test "raises SessionExpired on the sign-in page" do
    assert_raises(Kindle::Notebook::SessionExpired) { page("notebook_signed_out") }
  end

  test "raises LayoutChanged rather than reporting an empty success" do
    error = assert_raises(Kindle::Notebook::LayoutChanged) { page("notebook_changed_layout").highlights }
    assert_match(/markup has probably changed/, error.message)
  end

  test "raises LayoutChanged when the library has no books it recognises" do
    assert_raises(Kindle::Notebook::LayoutChanged) do
      Kindle::Notebook::Page.new("<html><body><div id='kp-notebook'>nothing familiar</div></body></html>").books
    end
  end
end
