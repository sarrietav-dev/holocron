module Book::Exportable
  extend ActiveSupport::Concern

  included do
    scope :stale_for_export, -> {
      where(arel_table[:obsidian_synced_at].eq(nil)
        .or(arel_table[:obsidian_synced_at].lt(arel_table[:updated_at])))
    }
  end

  def stale_for_export?
    obsidian_synced_at.nil? || obsidian_synced_at < updated_at
  end

  def exported!
    update_column :obsidian_synced_at, Time.current
  end
end
