# The read.amazon.com/notebook path: richer than My Clippings.txt (covers, ASINs,
# highlight colours) but dependent on a session cookie and on Amazon's markup,
# so it is kept entirely independent of the clippings path.
class Kindle::NotebookImport < ApplicationRecord
  has_one :import, as: :source, touch: true

  attr_writer :notebook

  def each_book(import, &block)
    notebook_for(import).each_book do |attributes, highlights|
      increment!(:books_seen)
      block.call(attributes, highlights)
    end
  end

  def label = "Amazon notebook"

  private
    def notebook_for(import)
      @notebook ||= Kindle::Notebook.new(credential: import.user.credential_for(Credential::AMAZON))
    end
end
