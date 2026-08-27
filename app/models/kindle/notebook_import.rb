# The read.amazon.com/notebook path: richer (covers, ASINs) but fragile.
class Kindle::NotebookImport < ApplicationRecord
  has_one :import, as: :source, touch: true

  def each_book(import, &block)
    notebook = Kindle::Notebook.new(credential: import.user.credential_for(Credential::AMAZON))
    notebook.each_book do |attributes, highlights|
      increment!(:books_seen)
      block.call(attributes, highlights)
    end
  end

  def label = "Amazon notebook"
end
