class Highlight < ApplicationRecord
  include Deduplicated, Discardable, Reviewable, Searchable, Taggable

  belongs_to :user
  belongs_to :book, counter_cache: :highlights_count, touch: true

  validates :text, presence: true

  # The Kindle highlighter inks, in the order Amazon lists them. Nil is a
  # normal value: My Clippings.txt records no color.
  COLORS = %w[ yellow blue pink orange ].freeze

  scope :favorited, -> { where(favorite: true) }
  scope :newest_first, -> { order(highlighted_at: :desc, id: :desc) }
  scope :in_reading_order, -> { order(Arel.sql("location_start IS NULL, location_start ASC, id ASC")) }

  def location
    return if location_start.blank?
    location_end.present? && location_end != location_start ? "#{location_start}-#{location_end}" : location_start.to_s
  end

  # Stable across re-syncs, so Obsidian block references keep resolving.
  def block_id = "hl-#{text_hash.first(8)}"

  def kindle_url
    "kindle://book?action=open&asin=#{book.asin}&location=#{location_start}" if book.asin.present? && location_start.present?
  end
end
