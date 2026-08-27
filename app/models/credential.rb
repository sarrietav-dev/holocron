class Credential < ApplicationRecord
  AMAZON   = "amazon_kindle".freeze
  OBSIDIAN = "obsidian_git".freeze

  belongs_to :user

  encrypts :data

  validates :provider, presence: true, uniqueness: { scope: :user_id }

  def settings = JSON.parse(data.presence || "{}").with_indifferent_access

  def settings=(hash)
    self.data = hash.to_h.compact_blank.to_json
  end

  def configured? = settings.present?
  def verified?   = verified_at.present?

  def verified!(note = nil)
    update! verified_at: Time.current, last_error: nil, last_used_at: Time.current
  end

  def failed!(message)
    update! last_error: message.to_s.truncate(500), last_used_at: Time.current
  end
end
