class ReviewsController < ApplicationController
  def show
    @review = Current.user.review_for
  end
end
