module Ding
  class Git
    include Ding::Helpers

    attr_reader :options

    def initialize(options={})
      @options = options
      raise "#{repo} is NOT a git repository" unless git_repo?
    end

    def local_branches(pattern)
      branches pattern, false
    end

    def remote_branches(pattern)
      branches pattern, true
    end

    def branches(pattern, remote=true)
      merged = options[:merged] ? '--merged' : '--no-merged'
      remote = '--remote' if remote
      %x(git branch #{remote} --list #{remote_version(pattern)} #{merged}).split
    end

    def branch_exists?(branch)
      ! %x(git branch --list #{branch}).empty?
    end

    def checkout(branch)
      raise "Unable to checkout #{branch}" unless run_cmd "git checkout #{branch}"
    end

    def create_branch(branch, checkout=true)
      raise "Unable to create #{branch}" unless run_cmd "git branch --no-track #{branch}"
      checkout(branch) if checkout
    end

    def current_branch
      %x(git rev-parse --abbrev-ref HEAD)
    end

    def delete_branch(branch)
      local_branch  = local_version(branch)
      remote_branch = remote_version(branch)
      raise "You are not allowed to delete #{local_branch}" if Ding::SACROSANCT_BRANCHES.include?(local_branch)
      if branch_exists?(local_branch)
        branch_cmd = "git branch #{options[:force] ? '-D' : '-d'} #{local_branch}"
        raise "Unable to delete #{local_branch}" unless run_cmd branch_cmd
      end
      if branch_exists?(remote_branch)
        branch_cmd = "git push #{remote_name} :#{local_branch} #{options[:force] ? '-f' : ''}"
        raise "Unable to delete #{remote_branch}" unless run_cmd branch_cmd
      end
    end

    def merge_branch(branch)
      raise "Can't merge into protected branch #{current_branch}" if Ding::SACROSANCT_BRANCHES.include?(current_branch)
      success = !!(run_cmd "git merge -m 'Merge branch #{branch} into #{current_branch}' #{branch}")
      unless success
        run_cmd 'git merge --abort'
      end
      success
    end

    def push(branch)
      checkout branch
      push_cmd = "git push #{remote_name} #{branch}"
      push_cmd << " --force" if options[:force]
      raise "Unable to push #{branch} branch!" unless run_cmd push_cmd
    end

    def branch_in_context(branch)
      if options[:local]
        local_version(branch)
      else
        remote_version(branch)
      end
    end

    def update
      command = options[:local] ? 'git up' : 'git fetch --all'
      raise "Error synchronising with the remote" unless run_cmd command
    end

    def reset_local_state
      run_cmd 'git rebase --abort'
      run_cmd 'git merge --abort'
      run_cmd 'git reset --hard'
    end

    def is_dirty?
      ! %x(git status -s).empty?
    end

    private

    def git_repo?
      run_cmd "git status"
    end

    def repo
      @repo || Dir.pwd
    end

    def remote_version(branch)
      if is_remote?(branch)
        branch
      else
        "#{remote_prefix}#{branch}"
      end
    end

    def local_version(branch)
      if is_remote?(branch)
        branch.gsub(remote_name, '')
      else
        branch
      end
    end

    def is_remote?(branch)
      branch.start_with?(remote_prefix)
    end

    def remote_name
      @remote_name ||= %x(git remote).chomp
    end

    def remote_prefix
      "#{remote_name}/"
    end
  end
end
