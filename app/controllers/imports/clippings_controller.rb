class Imports::ClippingsController < ApplicationController
  MAX_SIZE = 10.megabytes

  def create
    upload = params.expect(:file)
    raise ActionController::BadRequest, "Clippings file is too large" if upload.size > MAX_SIZE

    source = Kindle::ClippingsImport.new(filename: upload.original_filename,
      raw_text: upload.read.force_encoding(Encoding::UTF_8).scrub)
    import = Current.user.imports.create!(source: source)
    ClippingsImportJob.perform_later(import)
    redirect_to imports_path, status: :see_other, notice: "Clippings queued for import"
  end
end
