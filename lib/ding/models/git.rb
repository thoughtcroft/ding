module Ding
  class Git

    def initialize(options={})
      raise "#{repo} is NOT a git repository" unless git_repo?
      @options = options
    end

    def branches(pattern)
      merged = options[:merged] ? '--merged' : '--no-merged'
      %x(git branch --remote --list #{remote_version(pattern)} #{merged}).split.map {|b| b.split('/').last}
    end

    def branch_exists?(branch)
      ! %x(git branch --list #{branch}).empty?
    end

    def checkout(branch)
      raise "Unable to checkout #{branch}" unless run_cmd "git checkout #{branch}"
    end

    def create_branch(branch)
      raise "Unable to create #{branch}" unless run_cmd "git branch --track #{branch}"
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

    def push(branch)
      checkout branch
      push_cmd = "git push #{remote_name} #{branch}"
      push_cmd << " --force" if options[:force]
      raise "Unable to push #{branch} branch!" unless run_cmd push_cmd
    end

    def update
      raise "Error synchronising with the remote" unless run_cmd "git up"
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
      @remote_name || %x(git remote).chomp
    end

    def remote_prefix
      "#{remote_name}/"
    end

    # NOTE: only for commands where we are interested in the effect
    # as unless verbose is turned on, stdout and stderr are suppressed
    def run_cmd(cmd)
      cmd << ' &>/dev/null ' unless options[:verbose]
      system cmd
    end

    def options
      @options || {}
    end
  end
end
