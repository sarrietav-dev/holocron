require "fileutils"
require "open3"
require "tempfile"
require "uri"

class Obsidian::Vault
  class Error < StandardError; end

  DEFAULT_FOLDER = "Holocron".freeze

  def initialize(settings)
    @settings = settings.to_h.with_indifferent_access
  end

  def sync(books)
    prepare
    exported = books.select(&:stale_for_export?).each { |book| write(book) }
    publish
    exported.each(&:exported!)
    exported
  end

  def test
    authenticated_git "ls-remote", remote_url, "HEAD", chdir: Pathname("/")
    true
  end

  def write(book)
    path = note_path(book)
    FileUtils.mkdir_p(path.dirname)
    content = Obsidian::Note.new(book).render(path.exist? ? path.read : nil)

    Tempfile.create([ ".holocron", ".md" ], path.dirname) do |file|
      file.write(content)
      file.flush
      File.rename(file.path, path)
    end
  end

  def publish
    git "add", "--", relative_folder
    return false if git_success? "diff", "--cached", "--quiet"

    git "-c", "user.name=Holocron", "-c", "user.email=holocron@localhost",
      "commit", "-m", "Sync Kindle highlights"
    push
    true
  end

  private
    attr_reader :settings

    def prepare
      if (root / ".git").directory?
        git "pull", "--rebase"
      else
        FileUtils.mkdir_p(root.parent)
        authenticated_git "clone", remote_url, root.to_s, chdir: root.parent
      end
    end

    def push
      authenticated_git "push"
    rescue Error
      git "pull", "--rebase"
      authenticated_git "push"
    end

    def note_path(book)
      path = (root / relative_folder / Obsidian::Note.new(book).filename).expand_path
      base = (root / relative_folder).expand_path
      raise Error, "Obsidian folder escapes the vault" unless path.to_s.start_with?("#{base}/")

      path
    end

    def root
      @root ||= Pathname(settings.fetch(:local_path)).expand_path
    end

    def relative_folder
      @relative_folder ||= begin
        folder = Pathname(settings[:folder].presence || DEFAULT_FOLDER).cleanpath
        raise Error, "Obsidian folder must be relative" if folder.absolute? || folder.to_s.start_with?("..")

        folder.to_s
      end
    end

    def remote_url
      settings.fetch(:remote_url).then do |value|
        uri = URI(value)
        raise Error, "Obsidian remote must use HTTPS" unless uri.is_a?(URI::HTTPS)

        uri.user = settings[:token].present? ? settings[:username].presence || "x-access-token" : nil
        uri.password = nil
        uri.to_s
      rescue URI::InvalidURIError
        raise Error, "Obsidian remote URL is invalid"
      end
    end

    def git(*arguments, chdir: root)
      run_git({}, *arguments, chdir: chdir)
    end

    def authenticated_git(*arguments, chdir: root)
      return git(*arguments, chdir: chdir) if settings[:token].blank?

      Tempfile.create("holocron-askpass") do |helper|
        helper.write("#!/bin/sh\nprintf '%s\\n' \"$HOLOCRON_GIT_TOKEN\"\n")
        helper.close
        File.chmod(0o700, helper.path)
        run_git({ "GIT_ASKPASS" => helper.path, "GIT_TERMINAL_PROMPT" => "0", "HOLOCRON_GIT_TOKEN" => settings[:token] },
          *arguments, chdir: chdir)
      end
    end

    def git_success?(*arguments)
      _output, _error, status = Open3.capture3("git", *arguments, chdir: root.to_s)
      status.success?
    end

    def run_git(environment, *arguments, chdir:)
      output, error, status = Open3.capture3(environment, "git", *arguments, chdir: chdir.to_s)
      return output if status.success?

      raise Error, error.presence || "Git command failed"
    end
end
