class DailyReviewJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      next unless user.review_due_now?

      review = user.review_for
      next if review.highlights.empty?

      ReviewMailer.daily(review).deliver_now
      review.sent!
    end
  end
end
