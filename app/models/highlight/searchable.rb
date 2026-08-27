# Maintains the highlights_fts index in Ruby rather than in SQL triggers, because
# Rails does not dump triggers to schema.rb — a trigger-backed index would be
# missing after db:test:prepare and every search test would quietly pass against
# an empty table.
module Highlight::Searchable
  extend ActiveSupport::Concern

  RANKING = "bm25(highlights_fts, 10.0, 8.0, 3.0, 2.0)".freeze

  included do
    after_save_commit    :sync_search_index, unless: -> { self.class.indexing_suspended? }
    after_destroy_commit :remove_from_search_index
  end

  class_methods do
    # Bulk imports index once at the end instead of per row.
    def suspend_indexing
      previous, Thread.current[:holocron_indexing_suspended] = indexing_suspended?, true
      yield
    ensure
      Thread.current[:holocron_indexing_suspended] = previous
    end

    def indexing_suspended? = Thread.current[:holocron_indexing_suspended].present?

    # Kept free of a custom SELECT so that .count still builds COUNT(*).
    # Ask for #with_excerpts when the columns are actually going to be rendered.
    def matching(expression)
      # An empty expression is "MATCH ''", which FTS5 rejects outright. Callers
      # that mean "no filter" browse the table instead of coming through here.
      return none if expression.blank?

      joins("JOIN highlights_fts ON highlights_fts.rowid = highlights.id")
        .where("highlights_fts MATCH ?", expression)
        .order(Arel.sql(RANKING))
    end

    def with_excerpts
      select("highlights.*", "#{RANKING} AS search_rank",
             "snippet(highlights_fts, 0, '<mark>', '</mark>', '…', 24) AS search_excerpt")
    end

    # Turns whatever someone typed into a valid FTS5 expression. Bare terms are
    # quoted because -, *, :, ^ and " are all FTS5 syntax and would otherwise
    # raise on ordinary human queries; "quoted phrases" are preserved.
    def to_match_expression(query)
      terms = query.to_s.scan(/"([^"]*)"|(\S+)/).map { |phrase, word| phrase || word }
      terms.filter_map { |term|
        cleaned = term.gsub(/[^[:alnum:][:space:]'’]/, " ").squish
        %("#{cleaned}") if cleaned.present?
      }.join(" ")
    end

    def reindex(scope = all)
      connection.execute("DELETE FROM highlights_fts")
      scope.includes(:book).find_in_batches(batch_size: 500) do |batch|
        batch.each(&:sync_search_index)
      end
    end
  end

  def sync_search_index
    remove_from_search_index
    self.class.connection.exec_insert(<<~SQL, "Highlight FTS Insert", index_values)
      INSERT INTO highlights_fts (rowid, text, note, book_title, book_author)
      VALUES (?, ?, ?, ?, ?)
    SQL
  end

  def remove_from_search_index
    self.class.connection.exec_delete(
      "DELETE FROM highlights_fts WHERE rowid = ?", "Highlight FTS Delete", [ query_attribute(id) ]
    )
  end

  private
    def index_values
      [ id, text, note, book&.title, book&.author ].map { |value| query_attribute(value) }
    end

    def query_attribute(value)
      ActiveRecord::Relation::QueryAttribute.new(nil, value, ActiveModel::Type::Value.new)
    end
end
