require "test_helper"

class LibraryTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
    @book = @user.books.for(title: "Sapiens", author: "Yuval Noah Harari")
    @highlight = @book.highlights.record(text: "Stories let strangers cooperate.")
  end

  test "lists only the signed-in user's books" do
    users(:two).books.for(title: "Private Book", author: "Someone")

    get books_path

    assert_response :success
    assert_select "h2", text: "Sapiens"
    assert_select "h2", text: "Private Book", count: 0
  end

  test "shows a book and its highlights" do
    get book_path(@book)

    assert_response :success
    assert_select "blockquote", text: /Stories let strangers/
  end

  test "searches highlight text" do
    get search_path, params: { q: "strangers" }

    assert_response :success
    assert_select "mark", text: /strangers/
  end

  test "browses all highlights with an empty query" do
    get search_path

    assert_response :success
    assert_select "blockquote", text: /Stories let strangers/
  end

  test "filters search by tag" do
    @highlight.tag!("society")
    @book.highlights.record(text: "An unrelated passage.")

    get search_path, params: { q: "tag:society" }

    assert_response :success
    assert_select ".highlight", count: 1
  end
end
