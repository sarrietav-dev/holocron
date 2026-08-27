class Book < ApplicationRecord
  include Deduplicated, Exportable, Taggable

  belongs_to :user
  has_many :highlights, dependent: :destroy, extend: Highlight::Recording

  validates :title, presence: true

  scope :archived, -> { where.not(archived_at: nil) }
  scope :unarchived, -> { where(archived_at: nil) }
  scope :alphabetically, -> { order(Arel.sql("LOWER(title)")) }
  scope :recently_highlighted, -> { order(last_highlighted_at: :desc, id: :desc) }

  def archive!   = update!(archived_at: Time.current)
  def unarchive! = update!(archived_at: nil)
  def archived?  = archived_at.present?

  def display_author = author.presence || "Unknown author"
end
