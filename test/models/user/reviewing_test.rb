require "test_helper"

class User::ReviewingTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.update!(daily_review_size: 3, time_zone: "UTC")
    @book = @user.books.for(title: "Sapiens", author: "Yuval Noah Harari")
    10.times { |i| @book.highlights.record(text: "highlight number #{i}") }
  end

  test "asking twice on the same day returns the same review" do
    assert_equal @user.review_for.id, @user.review_for.id
    assert_equal 1, @user.reviews.count
  end

  test "does not reshuffle a review someone is already reading" do
    first = @user.review_for.highlights.map(&:id)
    assert_equal first, @user.review_for.highlights.map(&:id)
  end

  test "takes as many highlights as the setting asks for" do
    assert_equal 3, @user.review_for.highlights.count
  end

  test "never resurfaces a discarded highlight" do
    @book.highlights.each(&:discard!)
    kept = @book.highlights.record(text: "the only one left")

    assert_equal [ kept ], @user.review_for.highlights.to_a
  end

  test "never resurfaces highlights from an archived book" do
    @book.archive!
    assert_empty @user.review_for.highlights
  end

  test "prefers highlights that have never been reviewed" do
    @book.highlights.limit(8).each(&:reviewed!)
    unseen = @book.highlights.where(last_reviewed_at: nil).pluck(:id)

    assert_equal 2, unseen.size
    # Two unseen highlights and three slots, so both must be picked.
    assert_empty unseen - @user.review_for.highlights.pluck(:id)
  end

  test "records that a highlight was reviewed" do
    highlight = @book.highlights.first
    assert_difference -> { highlight.reload.reviews_count } do
      highlight.reviewed!
    end
    assert_not_nil highlight.reload.last_reviewed_at
  end

  test "builds a separate review for a different day" do
    today     = @user.review_for(Date.current)
    yesterday = @user.review_for(Date.current - 1)

    assert_not_equal today.id, yesterday.id
    assert_equal 2, @user.reviews.count
  end

  test "is due only in the user's own local hour" do
    @user.update!(daily_review_hour: @user.in_time_zone.hour)
    assert @user.review_due_now?

    @user.update!(daily_review_hour: (@user.in_time_zone.hour + 1) % 24)
    assert_not @user.review_due_now?
  end

  test "is not due when the user has turned it off" do
    @user.update!(daily_review_hour: @user.in_time_zone.hour, daily_review_enabled: false)
    assert_not @user.review_due_now?
  end

  test "reads today from the user's own time zone" do
    @user.update!(time_zone: "Auckland")
    assert_equal Time.current.in_time_zone("Auckland").to_date, @user.today
  end
end
