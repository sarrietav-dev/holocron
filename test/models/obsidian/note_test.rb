require "test_helper"

class Obsidian::NoteTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @book = @user.books.for(title: "Sapiens: A Brief History of Humankind",
                            author: "Yuval Noah Harari", asin: "B00ICN066A")
    @highlight = @book.highlights.record(text: "History is something very few people have been doing.",
                                         location_start: 145, location_end: 146)
  end

  def note = Obsidian::Note.new(@book.reload)

  test "writes front matter and the highlights" do
    markdown = note.render

    assert_match(/^title: "Sapiens: A Brief History of Humankind"$/, markdown)
    assert_match(/^author: "Yuval Noah Harari"$/, markdown)
    assert_match(/^asin: "B00ICN066A"$/, markdown)
    assert_match(/^## Highlights$/, markdown)
    assert_match(/History is something very few people have been doing\./, markdown)
  end

  test "links each highlight back into the Kindle app" do
    assert_match %r{\[Location 145-146\]\(kindle://book\?action=open&asin=B00ICN066A&location=145\)}, note.render
  end

  test "gives each highlight a stable block id" do
    assert_match(/\^#{@highlight.block_id}$/, note.render.lines.grep(/History is something/).first.strip)
  end

  test "keeps a block id stable across renders" do
    before = note.render[/\^hl-\w+/]
    @highlight.update!(color: "yellow")

    assert_equal before, note.render[/\^hl-\w+/]
  end

  test "renders notes and tags beneath their highlight" do
    @highlight.update!(note: "Compare with Diamond")
    @highlight.tag!("big history")

    markdown = note.render

    assert_match(/^    - \*\*Note:\*\* Compare with Diamond$/, markdown)
    assert_match(/^    - #big-history$/, markdown)
  end

  test "preserves everything written below the marker" do
    mine = "\n## My own thoughts\n\nThis book changed how I read history.\n"
    existing = note.render + mine

    rerendered = note.render(existing)

    assert_includes rerendered, "## My own thoughts"
    assert_includes rerendered, "This book changed how I read history."
    assert_equal 1, rerendered.scan(Obsidian::Note::MARKER).size
  end

  test "picks up new highlights while preserving what is below" do
    existing = note.render + "\n## Mine\n\nkeep me\n"
    @book.highlights.record(text: "Culture tends to argue that it forbids only the unnatural.")

    rerendered = note.render(existing)

    assert_includes rerendered, "Culture tends to argue"
    assert_includes rerendered, "keep me"
  end

  test "is idempotent when nothing has changed below the marker" do
    first = note.render
    assert_equal first.sub(/^synced:.*$/, ""), note.render(first).sub(/^synced:.*$/, "")
  end

  test "adds no trailing section when the file is new" do
    assert note.render.rstrip.end_with?(Obsidian::Note::MARKER)
  end

  test "flattens a multi-line highlight so it stays one list item" do
    @book.highlights.record(text: "First line.\n   Second line.")
    assert_match(/^- First line\. Second line\./, note.render.lines.grep(/First line/).first)
  end

  test "leaves discarded highlights out" do
    @highlight.discard!
    assert_match(/_No highlights yet\._/, note.render)
  end

  test "escapes a title containing a colon or a quote" do
    @book.update!(title: %q(A "Quoted": Title))
    assert_match(/^title: "A \\"Quoted\\": Title"$/, note.render)
  end

  test "strips characters that are unsafe in a filename" do
    @book.update!(title: "Notes on: C/C++ *and* #Rust?")

    assert_equal "Notes on C C++ and Rust (B00ICN066A).md", note.filename
  end

  test "keeps two books with the same title apart" do
    other = @user.books.for(title: "Sapiens: A Brief History of Humankind", author: "Someone Else", asin: "B0999")

    assert_not_equal Obsidian::Note.new(other).filename, note.filename
  end

  test "falls back to a name when the title sanitizes to nothing" do
    @book.update!(title: "///")
    assert_equal "Untitled (B00ICN066A).md", note.filename
  end

  test "truncates an unreasonably long title" do
    @book.update!(title: "A" * 400)
    assert_operator note.filename.length, :<=, Obsidian::Note::MAX_FILENAME + 30
  end
end
