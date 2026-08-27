require "test_helper"

class ImportTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  def clippings_import(text = file_fixture("my_clippings.txt").read)
    @user.imports.create!(source: Kindle::ClippingsImport.new(raw_text: text, filename: "My Clippings.txt"))
  end

  test "imports books and highlights from a clippings file" do
    import = clippings_import
    import.run

    assert_predicate import, :completed?
    assert_equal 3, @user.books.count
    assert_equal 3, @user.highlights.count
    assert_equal 3, import.books_created
  end

  test "importing the same file twice creates nothing new" do
    clippings_import.run

    replay = clippings_import
    replay.run

    assert_equal 0, replay.books_created
    assert_equal 0, replay.highlights_created
    assert_equal 3, @user.highlights.count
  end

  test "records when it started and finished" do
    import = clippings_import
    import.run

    assert_not_nil import.started_at
    assert_not_nil import.finished_at
    assert_predicate import, :finished?
  end

  test "records the failure rather than swallowing it" do
    import = clippings_import
    def import.absorb(*) = raise(IOError, "disk went away")

    assert_raises(IOError) { import.run }

    assert_predicate import.reload, :failed?
    assert_equal "IOError: disk went away", import.error_message
    assert_not_nil import.finished_at
  end

  test "stamps the book with when it was last highlighted" do
    clippings_import.run
    assert_not_nil @user.books.first.last_highlighted_at
  end

  test "leaves the highlights searchable afterwards" do
    clippings_import.run

    assert_includes Highlight.matching(Highlight.to_match_expression("people doing")),
                    @user.highlights.find_by(text: "History is something very few people have been doing.")
  end

  test "keeps the raw upload so a parser fix can be replayed" do
    import = clippings_import
    assert_match(/Sapiens/, import.source.raw_text)
  end
end
