# The Import row is the operation: its status column is the only place the
# progress of a sync is recorded.
#
# Transitions are verbs (start!/complete!/fail!) so they do not collide with the
# bang methods Rails' enum generates for each status value; the enum keeps the
# predicates (running?, completed?, failed?).
module Import::Runnable
  extend ActiveSupport::Concern

  STATUSES = %w[ pending running completed failed ].freeze

  included do
    enum :status, STATUSES.index_by(&:itself), validate: true
  end

  def start!
    update! status: :running, started_at: Time.current, error_message: nil
  end

  def complete!
    update! status: :completed, finished_at: Time.current
  end

  def fail!(error)
    update! status: :failed, finished_at: Time.current,
            error_message: "#{error.class}: #{error.message}".truncate(1000)
  end

  def finished? = completed? || failed?

  def duration
    return unless started_at && finished_at
    finished_at - started_at
  end

  def tally(counter)
    self.class.update_counters(id, counter => 1)
    self[counter] += 1
  end

  def summary
    "#{highlights_created} new, #{highlights_updated} updated, #{books_created} new books"
  end
end
