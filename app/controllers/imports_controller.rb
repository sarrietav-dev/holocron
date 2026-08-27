class ImportsController < ApplicationController
  include Pagination

  def index
    @imports = paginate(Current.user.imports.includes(:source).newest_first)
  end
end
