require "test_helper"

class DailyReviewJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "sends and marks a review at the user's configured hour" do
    user = users(:one)
    user.update!(time_zone: "UTC", daily_review_enabled: true, daily_review_hour: Time.current.utc.hour)
    user.books.for(title: "Sapiens", author: "Yuval Noah Harari").highlights.record(text: "A daily thought.")

    assert_emails 1 do
      DailyReviewJob.perform_now
    end

    assert_predicate user.reviews.find_by!(scheduled_for: user.today), :sent?
  end

  test "sends an unsent review that was already opened in the app" do
    user = users(:one)
    user.update!(time_zone: "UTC", daily_review_enabled: true, daily_review_hour: Time.current.utc.hour)
    user.books.for(title: "Sapiens", author: "Yuval Noah Harari").highlights.record(text: "Already selected.")
    review = user.review_for

    assert_emails 1 do
      DailyReviewJob.perform_now
    end

    assert_predicate review.reload, :sent?
  end

  test "does not send the same review twice" do
    user = users(:one)
    user.update!(time_zone: "UTC", daily_review_enabled: true, daily_review_hour: Time.current.utc.hour)
    user.books.for(title: "Sapiens", author: "Yuval Noah Harari").highlights.record(text: "Only once.")
    DailyReviewJob.perform_now

    assert_no_emails do
      DailyReviewJob.perform_now
    end
  end
end
