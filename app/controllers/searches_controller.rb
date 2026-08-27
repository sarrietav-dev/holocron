class SearchesController < ApplicationController
  include Pagination

  def show
    @query = params[:q].to_s.strip
    text, filters = parse(@query)
    scope = Current.user.highlights.kept.includes(:book, :tags)
    scope = scope.merge(Highlight.matching(Highlight.to_match_expression(text))) if text.present?
    scope = apply_filters(scope, filters)
    @highlights = paginate(text.present? ? scope : scope.newest_first)
    @highlights = @highlights.with_excerpts if text.present?
  end

  private
    def parse(query)
      filters = {}
      text = query.gsub(/\b(tag|book|author|favorite):("[^"]+"|\S+)/i) do
        filters[Regexp.last_match(1).downcase] = Regexp.last_match(2).delete_prefix('"').delete_suffix('"')
        ""
      end
      [ text.squish, filters ]
    end

    def apply_filters(scope, filters)
      scope = scope.tagged_with(filters["tag"]) if filters["tag"].present?
      scope = scope.joins(:book).where("books.title LIKE ?", "%#{Highlight.sanitize_sql_like(filters['book'])}%") if filters["book"].present?
      scope = scope.joins(:book).where("books.author LIKE ?", "%#{Highlight.sanitize_sql_like(filters['author'])}%") if filters["author"].present?
      scope = scope.favorited if ActiveModel::Type::Boolean.new.cast(filters["favorite"])
      scope
    end
end
