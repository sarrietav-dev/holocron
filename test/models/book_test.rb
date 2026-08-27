require "test_helper"

class BookTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "matches a book across sources that describe it differently" do
    from_clippings = @user.books.for(title: "Sapiens: A Brief History of Humankind", author: "Yuval Noah Harari")
    from_notebook  = @user.books.for(title: "Sapiens", author: "Yuval Noah Harari", asin: "B00ICN066A")

    assert_equal from_clippings.id, from_notebook.id
    assert_equal 1, @user.books.count
  end

  test "backfills the ASIN when a later source knows it" do
    book = @user.books.for(title: "Sapiens", author: "Yuval Noah Harari")
    assert_nil book.asin

    @user.books.for(title: "Sapiens", author: "Yuval Noah Harari", asin: "B00ICN066A", cover_image_url: "http://x/c.jpg")

    assert_equal "B00ICN066A", book.reload.asin
    assert_equal "http://x/c.jpg", book.cover_image_url
  end

  test "never lets a thinner source erase what a richer one recorded" do
    @user.books.for(title: "Sapiens", author: "Yuval Noah Harari", cover_image_url: "http://x/cover.jpg")
    book = @user.books.for(title: "Sapiens", author: "Yuval Noah Harari", cover_image_url: nil)

    assert_equal "http://x/cover.jpg", book.cover_image_url
  end

  test "prefers an ASIN match over a title match" do
    renamed = @user.books.for(title: "Old Title", author: "Someone", asin: "B01")
    found   = @user.books.for(title: "Completely Different", author: "Someone Else", asin: "B01")

    assert_equal renamed.id, found.id
  end

  test "keeps short titles intact rather than stripping them to nothing" do
    assert_equal "it|king", Book.dedupe_key_for("It", "King")
  end

  test "ignores case, accents and punctuation when matching" do
    assert_equal Book.dedupe_key_for("Les Misérables", "Victor Hugo"),
                 Book.dedupe_key_for("les miserables!", "victor  hugo")
  end

  test "scopes books to their owner" do
    users(:one).books.for(title: "Shared Title", author: "A")
    users(:two).books.for(title: "Shared Title", author: "A")

    assert_equal 1, users(:one).books.count
    assert_equal 1, users(:two).books.count
  end
end
