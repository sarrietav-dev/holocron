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

  test "a notebook sync merges into what clippings already imported" do
    clippings_import.run
    sapiens = @user.books.find_by(title: "Sapiens: A Brief History of Humankind")
    assert_nil sapiens.asin

    notebook_import.run

    # Same book, now with the ASIN and cover the notebook knows about.
    assert_equal sapiens.id, @user.books.find_by(title: "Sapiens: A Brief History of Humankind").id
    assert_equal "B00ICN066A", sapiens.reload.asin
    assert_match %r{sapiens}, sapiens.cover_image_url
  end

  test "the same highlight from both sources stays one highlight" do
    clippings_import.run
    before = @user.highlights.count

    notebook_import.run

    sapiens = @user.books.find_by(title: "Sapiens: A Brief History of Humankind")
    shared  = sapiens.highlights.find_by(text: "History is something very few people have been doing.")

    assert_equal "yellow", shared.color, "the notebook fills in the colour clippings never had"
    assert_equal "QUJDRDEyMw", shared.amazon_id, "and the Amazon id"
    assert_equal 145, shared.location_start,
      "but the location clippings already recorded is not overwritten: first source wins per field"
    assert_operator @user.highlights.count, :>, before, "the notebook also brings highlights clippings did not have"
    assert_equal 1, sapiens.highlights.where(text: shared.text).count
  end

  test "a failing notebook sync leaves the clippings data alone" do
    clippings_import.run
    imported = @user.highlights.count

    broken = @user.imports.create!(source: Kindle::NotebookImport.new)
    broken.source.notebook = Object.new.tap do |stub|
      def stub.each_book(*) = raise(Kindle::Notebook::SessionExpired, "cookie expired")
    end

    assert_raises(Kindle::Notebook::SessionExpired) { broken.run }

    assert_predicate broken.reload, :failed?
    assert_match(/cookie expired/, broken.error_message)
    assert_equal imported, @user.highlights.count
  end

  private
    def notebook_import
      @user.imports.create!(source: Kindle::NotebookImport.new).tap do |import|
        import.source.notebook = stubbed_notebook
      end
    end

    def stubbed_notebook
      library = Kindle::Notebook::Page.new(file_fixture("notebook_library.html").read).books
      pages   = Kindle::Notebook::Page.new(file_fixture("notebook_book.html").read).highlights

      Object.new.tap do |stub|
        stub.define_singleton_method(:each_book) do |&block|
          library.each { |book| block.call(book.except(:token), pages) }
        end
      end
    end
end
