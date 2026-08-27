class User < ApplicationRecord
  include Reviewing

  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :books, dependent: :destroy
  has_many :highlights, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :credentials, dependent: :destroy
  has_many :imports, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true
  validates :daily_review_size, numericality: { in: 1..20 }
  validates :daily_review_hour, numericality: { in: 0..23 }
  validates :time_zone, inclusion: { in: ->(_) { ActiveSupport::TimeZone.all.map(&:name) } }

  def credential_for(provider) = credentials.find_by(provider: provider)
end
