# The My Clippings.txt path: reliable, offline, no credentials.
class Kindle::ClippingsImport < ApplicationRecord
  has_one :import, as: :source, touch: true

  validates :raw_text, presence: true

  def each_book(_import, &block)
    Kindle::Clippings.new(raw_text).each_book(&block)
  end

  def label = filename.presence || "My Clippings.txt"
end
