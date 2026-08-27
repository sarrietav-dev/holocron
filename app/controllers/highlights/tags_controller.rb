class Highlights::TagsController < ApplicationController
  def create
    highlight.tag!(params.expect(:name))
    redirect_back fallback_location: root_path, status: :see_other
  end

  def destroy
    highlight.untag!(params[:id])
    redirect_back fallback_location: root_path, status: :see_other
  end

  private
    def highlight = Current.user.highlights.find(params[:highlight_id])
end
