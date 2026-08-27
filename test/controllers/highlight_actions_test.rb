require "test_helper"

class HighlightActionsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
    @book = @user.books.for(title: "Sapiens", author: "Yuval Noah Harari")
    @highlight = @book.highlights.record(text: "A passage worth keeping.")
  end

  test "favorites and unfavorites a highlight" do
    post highlight_favorite_path(@highlight)
    assert_predicate @highlight.reload, :favorite?

    delete highlight_favorite_path(@highlight)
    assert_not @highlight.reload.favorite?
  end

  test "discards and restores a highlight" do
    post highlight_discard_path(@highlight)
    assert_predicate @highlight.reload, :discarded?

    delete highlight_discard_path(@highlight)
    assert_not @highlight.reload.discarded?
  end

  test "updates a note" do
    patch highlight_note_path(@highlight), params: { highlight: { note: "Remember this" } }

    assert_equal "Remember this", @highlight.reload.note
  end

  test "adds and removes a tag" do
    post highlight_tags_path(@highlight), params: { name: "wisdom" }
    assert_equal [ "wisdom" ], @highlight.reload.tag_list

    delete highlight_tag_path(@highlight, "wisdom")
    assert_empty @highlight.reload.tags
  end

  test "cannot change another user's highlight" do
    other = users(:two).books.for(title: "Private", author: "Other").highlights.record(text: "Not yours")

    post highlight_favorite_path(other)

    assert_response :not_found
    assert_not other.reload.favorite?
  end
end
