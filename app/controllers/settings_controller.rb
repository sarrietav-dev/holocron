class SettingsController < ApplicationController
  def show
    load_credentials
  end

  def update
    Current.user.update!(params.expect(user: %i[ time_zone daily_review_enabled daily_review_hour daily_review_size ]))
    save_credential(Credential::AMAZON, params.dig(:amazon, :cookie))
    save_obsidian
    redirect_to settings_path, status: :see_other, notice: "Settings saved"
  end

  private
    def load_credentials
      @amazon = Current.user.credentials.find_or_initialize_by(provider: Credential::AMAZON)
      @obsidian = Current.user.credentials.find_or_initialize_by(provider: Credential::OBSIDIAN)
    end

    def save_credential(provider, secret)
      credential = Current.user.credentials.find_or_initialize_by(provider: provider)
      credential.settings = credential.settings.merge(cookie: secret.presence) if secret.present?
      credential.save! if credential.changed?
    end

    def save_obsidian
      values = params.fetch(:obsidian, {}).permit(:remote_url, :local_path, :folder, :username, :token).to_h.compact_blank
      credential = Current.user.credentials.find_or_initialize_by(provider: Credential::OBSIDIAN)
      credential.settings = credential.settings.merge(values)
      credential.save! if credential.changed?
    end
end
