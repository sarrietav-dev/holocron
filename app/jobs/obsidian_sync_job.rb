class ObsidianSyncJob < ApplicationJob
  queue_as :default

  def perform(user)
    credential = user.credential_for(Credential::OBSIDIAN)
    return unless credential&.configured?

    Obsidian::Vault.new(credential.settings).sync(user.books.includes(highlights: :tags).to_a)
    credential.verified!
  rescue => error
    credential&.failed!(error.message)
    raise
  end
end
