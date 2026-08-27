class BooksController < ApplicationController
  include Pagination

  def index
    books = Current.user.books.unarchived.includes(:tags)
    books = books.tagged_with(params[:tag]) if params[:tag].present?
    @books = paginate(params[:sort] == "recent" ? books.recently_highlighted : books.alphabetically)
  end

  def show
    @book = Current.user.books.find(params[:id])
    @highlights = paginate(@book.highlights.kept.includes(:tags).in_reading_order)
  end
end
