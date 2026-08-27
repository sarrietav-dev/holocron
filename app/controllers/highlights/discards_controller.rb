class Highlights::DiscardsController < ApplicationController
  def create
    highlight.discard!
    redirect_back fallback_location: root_path, status: :see_other
  end

  def destroy
    highlight.undiscard!
    redirect_back fallback_location: root_path, status: :see_other
  end

  private
    def highlight = Current.user.highlights.find(params[:highlight_id])
end
