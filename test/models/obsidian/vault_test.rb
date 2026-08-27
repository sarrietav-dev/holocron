require "test_helper"

class Obsidian::VaultTest < ActiveSupport::TestCase
  setup do
    @directory = Dir.mktmpdir
    @remote = Pathname(@directory) / "remote.git"
    @clone = Pathname(@directory) / "vault"
    system "git", "init", "--bare", @remote.to_s, exception: true, out: File::NULL

    @book = users(:one).books.for(title: "Sapiens", author: "Yuval Noah Harari", asin: "B00ICN066A")
    @book.highlights.record(text: "History began when humans invented gods.", location_start: 42)
    @vault = Obsidian::Vault.new(local_path: @clone, remote_url: "https://example.com/vault.git")
    remote = @remote.to_s
    @vault.define_singleton_method(:remote_url) { remote }
  end

  teardown do
    FileUtils.remove_entry(@directory)
  end

  test "clones, writes, commits, and pushes notes" do
    exported = @vault.sync([ @book ])

    assert_equal [ @book ], exported
    assert_predicate @clone / "Holocron" / "Sapiens (B00ICN066A).md", :file?
    assert_not_nil @book.reload.obsidian_synced_at
    assert system("git", "--git-dir", @remote.to_s, "rev-parse", "HEAD", out: File::NULL)
  end

  test "preserves edits below the marker on a later sync" do
    @vault.sync([ @book ])
    path = @clone / "Holocron" / "Sapiens (B00ICN066A).md"
    path.write(path.read + "\n## My notes\n\nKeep this.\n")
    system "git", "-C", @clone.to_s, "add", ".", exception: true
    system "git", "-C", @clone.to_s, "-c", "user.name=Test", "-c", "user.email=test@example.com",
      "commit", "-m", "Add personal notes", exception: true, out: File::NULL
    system "git", "-C", @clone.to_s, "push", exception: true, out: File::NULL

    @book.highlights.record(text: "Newly imported highlight.")
    @vault.sync([ @book.reload ])

    assert_includes path.read, "Newly imported highlight."
    assert_includes path.read, "Keep this."
  end

  test "does nothing when every book is already synced" do
    @vault.sync([ @book ])

    assert_no_changes -> { `git --git-dir=#{@remote} rev-parse HEAD`.strip } do
      assert_empty @vault.sync([ @book.reload ])
    end
  end

  test "rejects a folder outside the vault" do
    vault = Obsidian::Vault.new(local_path: @clone, remote_url: "https://example.com/vault.git", folder: "../elsewhere")

    assert_raises(Obsidian::Vault::Error) { vault.send(:relative_folder) }
  end

  test "does not put an authentication token in the remote URL" do
    vault = Obsidian::Vault.new(local_path: @clone, remote_url: "https://github.com/example/vault.git", token: "secret")

    assert_equal "https://x-access-token@github.com/example/vault.git", vault.send(:remote_url)
  end
end
