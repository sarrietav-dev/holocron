require "test_helper"

class ImportsAndSettingsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "renders import history and settings" do
    get imports_path
    assert_response :success

    get settings_path
    assert_response :success
    assert_select "h2", text: "Amazon Notebook"
  end

  test "uploads My Clippings and queues its import" do
    file = fixture_file_upload("my_clippings.txt", "text/plain")

    assert_enqueued_with(job: ClippingsImportJob) do
      post imports_clippings_path, params: { file: file }
    end

    assert_redirected_to imports_path
    assert_equal "my_clippings.txt", @user.imports.last.source.filename
  end

  test "queues an Amazon notebook sync" do
    assert_enqueued_with(job: NotebookSyncJob) do
      post imports_notebook_path
    end
  end

  test "saves review and encrypted integration settings" do
    patch settings_path, params: {
      user: { time_zone: "UTC", daily_review_enabled: "1", daily_review_hour: "9", daily_review_size: "7" },
      amazon: { cookie: "session=secret" },
      obsidian: { remote_url: "https://github.com/me/vault.git", local_path: "/data/vault", folder: "Books", token: "git-secret" }
    }

    assert_redirected_to settings_path
    assert_equal 7, @user.reload.daily_review_size
    assert_equal "session=secret", @user.credential_for(Credential::AMAZON).settings[:cookie]
    assert_equal "git-secret", @user.credential_for(Credential::OBSIDIAN).settings[:token]
    assert_not_includes Credential.find_by(provider: Credential::AMAZON).ciphertext_for(:data), "secret"
  end

  test "blank secret fields keep saved credentials" do
    credential = @user.credentials.create!(provider: Credential::AMAZON, settings: { cookie: "keep-me" })

    patch settings_path, params: {
      user: { time_zone: "UTC", daily_review_enabled: "1", daily_review_hour: "8", daily_review_size: "5" },
      amazon: { cookie: "" }, obsidian: {}
    }

    assert_equal "keep-me", credential.reload.settings[:cookie]
  end

  test "queues an Obsidian sync" do
    assert_enqueued_with(job: ObsidianSyncJob, args: [ @user ]) do
      post obsidian_sync_path
    end
  end
end
