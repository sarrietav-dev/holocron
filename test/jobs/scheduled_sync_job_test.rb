require "test_helper"

class ScheduledSyncJobTest < ActiveJob::TestCase
  test "queues configured Kindle and Obsidian integrations" do
    user = users(:one)
    user.credentials.create!(provider: Credential::AMAZON, settings: { cookie: "session=abc" })
    user.credentials.create!(provider: Credential::OBSIDIAN,
      settings: { remote_url: "https://example.com/vault.git", local_path: "/tmp/vault" })

    assert_enqueued_with(job: NotebookSyncJob) do
      assert_enqueued_with(job: ObsidianSyncJob, args: [ user ]) do
        ScheduledSyncJob.perform_now
      end
    end

    assert_instance_of Kindle::NotebookImport, user.imports.last.source
  end

  test "skips integrations that are not configured" do
    assert_no_enqueued_jobs do
      ScheduledSyncJob.perform_now
    end
  end
end
