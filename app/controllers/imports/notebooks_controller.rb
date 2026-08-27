class Imports::NotebooksController < ApplicationController
  def create
    import = Current.user.imports.create!(source: Kindle::NotebookImport.new)
    NotebookSyncJob.perform_later(import)
    redirect_to imports_path, status: :see_other, notice: "Amazon sync queued"
  end
end
