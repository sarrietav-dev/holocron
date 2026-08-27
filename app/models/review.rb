class Review < ApplicationRecord
  belongs_to :user
  has_many :review_highlights, -> { order(:position) }, dependent: :destroy
  has_many :highlights, through: :review_highlights

  scope :newest_first, -> { order(scheduled_for: :desc) }

  def sent?      = sent_at.present?
  def completed? = completed_at.present?

  def sent!      = update!(sent_at: Time.current)
  def complete!  = update!(completed_at: Time.current)

  def today? = scheduled_for == Date.current
end
