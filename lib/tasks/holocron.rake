namespace :holocron do
  desc "Rebuild the full-text highlight index"
  task reindex: :environment do
    Highlight.reindex
    puts "Indexed #{Highlight.count} highlights."
  end
end
