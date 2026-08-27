class ReviewHighlight < ApplicationRecord
  belongs_to :review
  belongs_to :highlight
end
