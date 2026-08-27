module PaginationHelper
  def pagination
    return unless previous_page? || next_page?

    tag.nav class: "pagination", aria: { label: "Pagination" } do
      safe_join([
        (link_to("← Newer", url_for(request.query_parameters.merge(page: @page - 1)), class: "button quiet") if previous_page?),
        tag.span("Page #{@page}", class: "pagination__count"),
        (link_to("Older →", url_for(request.query_parameters.merge(page: @page + 1)), class: "button quiet") if next_page?)
      ].compact)
    end
  end
end
