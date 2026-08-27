require "test_helper"

class ReviewMailerTest < ActionMailer::TestCase
  test "renders the review in HTML and plain text" do
    user = users(:one)
    book = user.books.for(title: "Sapiens", author: "Yuval Noah Harari")
    book.highlights.record(text: "Stories bind strangers together.")
    review = user.review_for

    mail = ReviewMailer.daily(review)

    assert_equal [ user.email_address ], mail.to
    assert_equal "Your daily Holocron review", mail.subject
    assert_includes mail.html_part.body.to_s, "Stories bind strangers together."
    assert_includes mail.text_part.body.to_s, "Sapiens"
  end
end
