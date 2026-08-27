class Tag < ApplicationRecord
  belongs_to :user
  has_many :taggings, dependent: :destroy

  validates :name, :slug, presence: true

  scope :alphabetically, -> { order(Arel.sql("LOWER(name)")) }

  def self.for(user:, name:)
    slug = slugify(name)
    return if slug.blank?
    user.tags.create_with(name: name.to_s.strip).find_or_create_by!(slug: slug)
  rescue ActiveRecord::RecordNotUnique
    user.tags.find_by!(slug: slug)
  end

  def self.slugify(name)
    name.to_s.strip.downcase.gsub(/[^\p{Alnum}\s-]/, "").squish.tr(" ", "-")
  end

  def to_param = slug
end
