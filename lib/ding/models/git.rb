module Ding
  class Git

    def initialize
      raise "Not a git repository: #{repo}" unless git_repo?
    end

    def branches(pattern)
      %x(git branch --remote --list #{pattern}).split.map {|b| b.split('/').last}
    end

    def checkout(branch)
      raise "Unable to checkout #{branch}" unless system "git", "checkout", branch
    end

    def create_branch(branch)
      raise "Unable to create #{branch}" unless system "git", "branch", "--track", branch
    end

    def delete_branch(branch)
      return unless branch_exists? branch
      raise "You are not allowed to delete #{branch} branch!" if [ 'master', 'develop' ].include?(branch)
      raise "Unable to delete local #{branch} branch!" unless system "git", "branch", "-d", branch
      raise "Unable to delete remote #{branch} branch!" unless system "git", "push", "origin", ":#{branch}"
    end

    def push(branch)
      checkout branch
      raise "Unable to push #{branch} branch!" unless system "git", "push", "origin", branch
    end

    def update
      raise "Error synchronising with remote" unless system "git", "up"
    end

    private

    def branch_exists?(branch)
      ! %x(git branch --list #{branch}).empty?
    end

    def git_repo?
      system "git", "status"
    end

    def repo
      @repo || Dir.pwd
    end

  end
end
