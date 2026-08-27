# Resolves a book from whatever a Kindle source happens to know about it.
#
# My Clippings.txt gives only a title and author; the Kindle notebook also gives
# an ASIN and a cover. Matching on a normalized title+author key lets the second
# source find the book the first one created, and enrich it in place rather than
# creating a duplicate.
module Book::Deduplicated
  extend ActiveSupport::Concern

  ENRICHABLE = %i[ asin cover_image_url author ].freeze

  included do
    before_validation :assign_dedupe_key
    validates :dedupe_key, presence: true
  end

  class_methods do
    # Returns a persisted book, creating or enriching it as needed.
    def for(title:, author: nil, asin: nil, **attributes)
      book = locate(asin: asin, title: title, author: author) ||
             new(title: title, author: author, asin: asin.presence)

      book.enrich(asin: asin, author: author, **attributes)
      book.save!
      book
    end

    def dedupe_key_for(title, author)
      [ normalize(strip_subtitle(title)), normalize(author) ].join("|")
    end

    private
      def locate(asin:, title:, author:)
        (asin.present? && find_by(asin: asin)) ||
          find_by(dedupe_key: dedupe_key_for(title, author))
      end

      # "Sapiens: A Brief History of Humankind" and "Sapiens" are the same book.
      # Only strip when something substantial remains on the left.
      def strip_subtitle(title)
        head = title.to_s.split(/\s*[:—–]\s*/).first
        head.present? && head.length >= 4 ? head : title.to_s
      end

      def normalize(value)
        value.to_s
             .unicode_normalize(:nfkd)
             .gsub(/\p{Mn}/, "")
             .downcase
             .gsub(/[^\p{Alnum}\s]/, " ")
             .squish
      end
  end

  # Fills blanks only. A source that knows less must never erase what a source
  # that knew more already recorded.
  def enrich(**attributes)
    attributes.slice(*ENRICHABLE).each do |name, value|
      self[name] = value if value.present? && self[name].blank?
    end
  end

  private
    def assign_dedupe_key
      self.dedupe_key = self.class.dedupe_key_for(title, author)
    end
end
