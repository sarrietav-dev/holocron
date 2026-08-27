# The Import row is the operation: its status column is the only place the
# progress of a sync is recorded.
module Import::Runnable
  extend ActiveSupport::Concern

  STATUSES = %w[ pending running completed failed ].freeze

  included do
    enum :status, STATUSES.index_by(&:itself), validate: true
  end

  def running!
    update! status: :running, started_at: Time.current, error_message: nil
  end

  def completed!
    update! status: :completed, finished_at: Time.current
  end

  def failed!(error)
    update! status: :failed, finished_at: Time.current,
            error_message: "#{error.class}: #{error.message}".truncate(1000)
  end

  def finished? = completed? || failed?

  def duration
    return unless started_at && finished_at
    finished_at - started_at
  end

  def increment(counter)
    self.class.update_counters(id, counter => 1)
    self[counter] += 1
  end

  def summary
    "#{highlights_created} new, #{highlights_updated} updated, #{books_created} new books"
  end
end
