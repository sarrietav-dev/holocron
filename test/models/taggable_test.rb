require "test_helper"

class TaggableTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @book = @user.books.for(title: "Sapiens", author: "Yuval Noah Harari")
    @highlight = @book.highlights.record(text: "A highlight worth tagging")
  end

  test "tagging twice does not tag twice" do
    2.times { @highlight.tag!("Big History") }

    assert_equal [ "Big History" ], @highlight.tag_list
    assert_equal 1, Tagging.count
  end

  test "matches tags that differ only in case or spacing" do
    @highlight.tag!("Big History")
    @highlight.tag!("  big   history ")

    assert_equal 1, @user.tags.count
  end

  test "tags books and highlights from the same vocabulary" do
    @highlight.tag!("history")
    @book.tag!("history")

    assert_equal 1, @user.tags.count
    assert_includes Book.tagged_with("history"), @book
    assert_includes Highlight.tagged_with("history"), @highlight
  end

  test "untagging leaves the tag itself alone for other records" do
    @highlight.tag!("history")
    @book.tag!("history")

    @highlight.untag!("history")

    assert_empty @highlight.tag_list
    assert_equal [ "history" ], @book.tag_list
    assert_equal 1, @user.tags.count
  end

  test "untagging something that was never tagged is harmless" do
    assert_nothing_raised { @highlight.untag!("never-applied") }
  end

  test "ignores a tag that normalizes to nothing" do
    @highlight.tag!("!!!")
    assert_empty @highlight.tag_list
  end

  test "keeps each user's vocabulary separate" do
    @highlight.tag!("history")
    users(:two).books.for(title: "Other", author: "B").tag!("history")

    assert_equal 1, users(:one).tags.count
    assert_equal 1, users(:two).tags.count
  end
end
