# The daily review is just a method on the user — there is no builder object,
# because there is no state to hold that the user does not already have.
module User::Reviewing
  extend ActiveSupport::Concern

  included do
    has_many :reviews, dependent: :destroy
  end

  # Idempotent per day: asking twice returns the same review, so a retried job
  # never reshuffles a review someone is already reading.
  def review_for(date = today)
    reviews.find_by(scheduled_for: date) || build_review_for(date)
  end

  def review_due_now?
    daily_review_enabled? && in_time_zone.hour == daily_review_hour && !reviews.exists?(scheduled_for: today, sent_at: nil..)
  end

  def today = in_time_zone.to_date

  def in_time_zone = Time.current.in_time_zone(time_zone)

  private
    def build_review_for(date)
      transaction do
        review = reviews.create!(scheduled_for: date)
        highlights.due.limit(daily_review_size).each_with_index do |highlight, index|
          review.review_highlights.create!(highlight: highlight, position: index)
        end
        review
      end
    rescue ActiveRecord::RecordNotUnique
      reviews.find_by!(scheduled_for: date)
    end
end
