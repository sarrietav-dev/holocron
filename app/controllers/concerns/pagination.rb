module Pagination
  extend ActiveSupport::Concern

  PER_PAGE = 30

  included do
    helper_method :next_page?, :previous_page?
  end

  private
    def paginate(scope)
      @page = [ params.fetch(:page, 1).to_i, 1 ].max
      @total_count = scope.count
      scope.limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
    end

    def next_page? = @page * PER_PAGE < @total_count
    def previous_page? = @page > 1
end
