module Ding
  class Git

    def initialize
      raise "#{repo} is NOT a git repository" unless git_repo?
    end

    def branches(pattern)
      %x(git branch --remote --list origin/#{pattern}).split.map {|b| b.split('/').last}
    end

    def branch_exists?(branch)
      ! %x(git branch --list #{branch}).empty?
    end

    def checkout(branch)
      raise "Unable to checkout #{branch}" unless system "git checkout #{branch}"
    end

    def create_branch(branch)
      raise "Unable to create #{branch}" unless system "git branch --track #{branch}"
    end

    def delete_branch(branch, force=false)
      return unless branch_exists? branch
      raise "You are not allowed to delete #{branch} branch!" if Ding::SACROSANCT_BRANCHES.include?(branch)
      raise "Unable to delete local #{branch} branch!" unless system "git branch #{force ? '-D' : '-d'} #{branch}"
      raise "Unable to delete remote #{branch} branch!" unless system "git push origin :#{branch}"
    end

    def push(branch)
      checkout branch
      raise "Unable to push #{branch} branch!" unless system "git push origin #{branch}"
    end

    def update
      raise "Error synchronising with the remote" unless system "git up"
    end

    private

    def git_repo?
      system "git status"
    end

    def repo
      @repo || Dir.pwd
    end
  end
end
