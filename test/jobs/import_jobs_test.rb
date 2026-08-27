require "test_helper"

class ImportJobsTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    source = Kindle::ClippingsImport.new(raw_text: file_fixture("my_clippings.txt").read, filename: "My Clippings.txt")
    @import = @user.imports.create!(source: source)
  end

  test "runs a clippings import and schedules an export" do
    assert_enqueued_with(job: ObsidianSyncJob, args: [ @user ]) do
      ClippingsImportJob.perform_now(@import)
    end

    assert_predicate @import.reload, :completed?
    assert_equal 3, @user.highlights.count
  end

  test "does not schedule an export when the import fails" do
    @import.define_singleton_method(:absorb) { |*| raise IOError, "disk failed" }

    assert_no_enqueued_jobs(only: ObsidianSyncJob) do
      assert_raises(IOError) { ClippingsImportJob.perform_now(@import) }
    end
  end

  test "skips Obsidian when it is not configured" do
    assert_nothing_raised { ObsidianSyncJob.perform_now(@user) }
  end
end
