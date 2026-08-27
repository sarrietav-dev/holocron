class ReviewMailer < ApplicationMailer
  def daily(review)
    @review = review
    mail to: review.user.email_address, subject: "Your daily Holocron review"
  end
end
