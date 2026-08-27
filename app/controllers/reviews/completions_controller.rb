class Reviews::CompletionsController < ApplicationController
  def create
    Current.user.review_for.complete!
    redirect_to root_path, status: :see_other, notice: "Review complete"
  end
end
