class Credentials::TestsController < ApplicationController
  def create
    credential = Current.user.credentials.find_by!(provider: params[:provider])
    result = test(credential)
    credential.verified!
    redirect_to settings_path, status: :see_other, notice: connection_message(credential, result)
  rescue Kindle::Notebook::Error, Obsidian::Vault::Error => error
    credential&.failed!(error.message)
    redirect_to settings_path, status: :see_other, alert: error.message
  end

  private
    def test(credential)
      case credential.provider
      when Credential::AMAZON then Kindle::Notebook.new(credential: credential).test
      when Credential::OBSIDIAN then Obsidian::Vault.new(credential.settings).test
      else raise ActiveRecord::RecordNotFound
      end
    end

    def connection_message(credential, result)
      credential.provider == Credential::AMAZON ? "Connected to #{result} Kindle books" : "Connected to Obsidian repository"
    end
end
