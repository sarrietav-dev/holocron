class Highlights::NotesController < ApplicationController
  def update
    highlight.update!(params.expect(highlight: [ :note ]))
    redirect_back fallback_location: book_path(highlight.book), status: :see_other
  end

  private
    def highlight = Current.user.highlights.find(params[:highlight_id])
end
