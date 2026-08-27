class Obsidian::SyncsController < ApplicationController
  def create
    ObsidianSyncJob.perform_later(Current.user)
    redirect_to settings_path, status: :see_other, notice: "Obsidian sync queued"
  end
end
