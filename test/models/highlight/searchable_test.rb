require "test_helper"

class Highlight::SearchableTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @book = @user.books.for(title: "Sapiens", author: "Yuval Noah Harari")
    @highlight = @book.highlights.record(text: "History is something very few people have been doing")
  end

  def search(query)
    Highlight.matching(Highlight.to_match_expression(query))
  end

  test "finds a highlight by its words" do
    assert_includes search("people doing"), @highlight
  end

  test "stems, so a different form of the word still matches" do
    assert_includes search("thinking"), @book.highlights.record(text: "I think about it")
  end

  test "searches the book title and author too" do
    assert_includes search("Harari"), @highlight
    assert_includes search("Sapiens"), @highlight
  end

  test "searches notes" do
    @highlight.update!(note: "compare with Diamond")
    assert_includes search("Diamond"), @highlight
  end

  test "survives punctuation that is FTS5 syntax" do
    %w[ foo-bar foo* :colon ^caret NEAR AND OR ].each do |query|
      assert_nothing_raised { search(query).to_a }
    end
    assert_nothing_raised { search(%q(an "unbalanced quote)).to_a }
    assert_nothing_raised { search("").to_a }
  end

  test "honours a quoted phrase" do
    @book.highlights.record(text: "people have been doing something else entirely")

    assert_equal 1, search(%q("very few people")).count
  end

  test "counts without tripping over the excerpt columns" do
    assert_equal 1, search("people").count
    assert_match(/<mark>people<\/mark>/, search("people").with_excerpts.first.search_excerpt)
  end

  test "drops out of the index when the highlight goes" do
    @highlight.destroy!
    assert_empty search("people doing")
  end

  test "follows an edit to the text" do
    @highlight.update!(text: "completely different words now")

    assert_empty search("people doing")
    assert_includes search("completely different"), @highlight
  end

  test "reindex rebuilds everything from scratch" do
    ActiveRecord::Base.connection.execute("DELETE FROM highlights_fts")
    assert_empty search("people doing")

    Highlight.reindex

    assert_includes search("people doing"), @highlight
  end

  test "suspended indexing defers the write until reindex" do
    Highlight.suspend_indexing do
      @book.highlights.record(text: "written while suspended")
    end
    assert_empty search("suspended")

    Highlight.reindex
    assert_equal 1, search("suspended").count
  end
end
