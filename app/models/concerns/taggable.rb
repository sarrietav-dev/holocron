# Shared by Book and Highlight — the only concern in app/models/concerns,
# because it is the only one two models genuinely share.
module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy
    has_many :tags, through: :taggings

    scope :tagged_with, ->(name) { joins(:tags).where(tags: { slug: Tag.slugify(name) }) }
  end

  def tag!(name)
    tag = Tag.for(user: user, name: name) or return
    taggings.find_or_create_by!(tag: tag)
    tags.reset
  end

  def untag!(name)
    tag = tags.find_by(slug: Tag.slugify(name)) or return
    taggings.where(tag: tag).destroy_all
    tags.reset
  end

  def tag_list = tags.map(&:name).sort_by(&:downcase)
end
