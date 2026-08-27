# Resurfacing, not memorization: highlights you have never seen come first,
# then the ones you have seen least recently, with favorites weighted up.
module Highlight::Reviewable
  extend ActiveSupport::Concern

  FAVORITE_WEIGHT = 0.5

  included do
    has_many :review_highlights, dependent: :destroy
    has_many :reviews, through: :review_highlights

    scope :due, -> {
      kept.joins(:book).merge(Book.unarchived)
          .order(Arel.sql(<<~SQL.squish))
            last_reviewed_at IS NOT NULL,
            (CASE WHEN favorite THEN #{FAVORITE_WEIGHT} ELSE 1.0 END) * ABS(RANDOM() / 9223372036854775808.0)
          SQL
    }
  end

  def reviewed!
    increment!(:reviews_count, touch: false)
    update_column :last_reviewed_at, Time.current
  end
end
