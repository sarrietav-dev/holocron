class ScheduledSyncJob < ApplicationJob
  queue_as :default

  def perform
    User.find_each do |user|
      if user.credential_for(Credential::AMAZON)&.configured?
        import = user.imports.create!(source: Kindle::NotebookImport.new)
        NotebookSyncJob.perform_later(import)
      end

      ObsidianSyncJob.perform_later(user) if user.credential_for(Credential::OBSIDIAN)&.configured?
    end
  end
end
