# A discarded highlight stays in the library but never surfaces in a review again.
module Highlight::Discardable
  extend ActiveSupport::Concern

  included do
    scope :discarded, -> { where.not(discarded_at: nil) }
    scope :kept,      -> { where(discarded_at: nil) }
  end

  def discard!   = update!(discarded_at: Time.current)
  def undiscard! = update!(discarded_at: nil)
  def discarded? = discarded_at.present?
end
