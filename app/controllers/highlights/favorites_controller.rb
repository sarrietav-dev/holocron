class Highlights::FavoritesController < ApplicationController
  def create
    highlight.update!(favorite: true)
    redirect_back fallback_location: root_path, status: :see_other
  end

  def destroy
    highlight.update!(favorite: false)
    redirect_back fallback_location: root_path, status: :see_other
  end

  private
    def highlight = Current.user.highlights.find(params[:highlight_id])
end
