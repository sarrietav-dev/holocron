class ClippingsImportJob < ApplicationJob
  queue_as :default

  def perform(import)
    import.run
    ObsidianSyncJob.perform_later(import.user)
  end
end
