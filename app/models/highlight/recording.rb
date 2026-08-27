# Association extension on book.highlights, so a Kindle source can hand over
# whatever it knows and let the record sort out create-versus-enrich.
module Highlight::Recording
  def record(text:, **attributes)
    highlight = find_or_initialize_by(text_hash: Highlight.hash_for(text))
    highlight.user_id ||= proxy_association.owner.user_id
    highlight.text = text if highlight.new_record?
    highlight.enrich(**attributes)
    highlight.save!
    highlight
  end
end
