require "bundler/gem_tasks"

Rake::TaskManager.class_eval do
  def delete_task(task)
    @tasks.delete(task.to_s)
  end
end

def delete_task(task)
  Rake.application.delete_task(task)
end

def version
  gemspec.version
end

def gemspec
  Bundler.load_gemspec(gemspec_path)
end

def gemspec_path
  Dir[File.join(FileUtils.pwd, "{,*}.gemspec")].first
end

def git_pull_source
  [
    'git fetch --all',
    'git reset --hard origin/master',
    'git pull'
  ].each do |c|
    `#{c} 2>&1`
  end
end


task :default => :install

delete_task :release        # don't publish to ruby gems
delete_task "install:local" # simplify install options

desc "Create new tag v#{version} and push to source control"
task "release" => ["release:guard_clean", "release:source_control_push"]

desc "Update the gem from the remote and install new version"
task "update" => ["release:guard_clean", "source_control_pull","install"]

task "source_control_pull" do
  git_pull_source
end
