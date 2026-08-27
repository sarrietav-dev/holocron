# The same highlight arriving from My Clippings.txt and from the Kindle notebook
# normalizes to the same text_hash, so the second source enriches the first one's
# record instead of creating a duplicate.
module Highlight::Deduplicated
  extend ActiveSupport::Concern

  # Deliberately excludes :text and :favorite. Never :note — a note you typed
  # outranks anything a sync has to say.
  ENRICHABLE = %i[ location_start location_end page chapter color amazon_id highlighted_at ].freeze

  included do
    before_validation :assign_text_hash
    validates :text_hash, presence: true
  end

  class_methods do
    def hash_for(text) = Digest::SHA256.hexdigest(normalize_text(text))

    # Collapses the differences that are not differences: whitespace, case, and
    # the trailing ellipsis the Kindle adds to a clipped highlight.
    def normalize_text(text)
      text.to_s.unicode_normalize(:nfkc).gsub(/[[:space:]]+/, " ").strip.sub(/[….]+\z/, "").downcase
    end
  end

  def enrich(**attributes)
    attributes.slice(*ENRICHABLE).each do |name, value|
      self[name] = value if value.present? && self[name].blank?
    end
    self.note = attributes[:note] if attributes[:note].present? && note.blank?
  end

  private
    def assign_text_hash
      self.text_hash = self.class.hash_for(text)
    end
end
