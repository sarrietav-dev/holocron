require "test_helper"

class Book::SpectrumTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "reports each color's share of a book's highlights" do
    book = book_with("yellow" => 3, "blue" => 1)

    assert_equal [ "yellow", "blue" ], book.spectrum.map(&:color)
    assert_equal [ 3, 1 ], book.spectrum.map(&:count)
    assert_in_delta 0.75, book.spectrum.first.share
  end

  test "orders colors the way Amazon lists them, whatever order they arrived in" do
    book = book_with("orange" => 1, "yellow" => 1, "pink" => 1, "blue" => 1)

    assert_equal Highlight::COLORS, book.spectrum.map(&:color)
  end

  test "treats uncolored highlights as a band of their own, always last" do
    book = book_with(nil => 2, "blue" => 1)
    bands = book.spectrum

    assert_equal [ "blue", nil ], bands.map(&:color)
    assert_equal "unmarked", bands.last.label
  end

  test "ignores discarded highlights" do
    book = book_with("yellow" => 2)
    book.highlights.first.discard!

    assert_equal [ 1 ], book.reload.spectrum.map(&:count)
  end

  test "has nothing to say about a book with no highlights" do
    assert_empty @user.books.create!(title: "Empty", dedupe_key: "empty").spectrum
  end

  test "preloads a whole page of books in one query" do
    books = [ book_with("yellow" => 2), book_with("blue" => 1) ]

    Book.preload_spectrum(books)

    assert_no_queries do
      assert_equal [ [ "yellow" ], [ "blue" ] ], books.map { |book| book.spectrum.map(&:color) }
    end
  end

  private
    def book_with(counts)
      book = @user.books.create!(title: "Book #{@user.books.count + 1}", dedupe_key: "book-#{@user.books.count + 1}")
      n = 0
      counts.each do |color, count|
        count.times do
          text = "#{book.dedupe_key} passage #{n += 1}"
          @user.highlights.create!(book: book, text: text, color: color, text_hash: Highlight.hash_for(text))
        end
      end
      book
    end
end
