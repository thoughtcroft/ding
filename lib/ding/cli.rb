require 'thor'

module Ding
  class Cli < Thor

    desc "test", "Push a feature branch to the testing branch"
    option :force,   type: 'boolean', aliases: '-f', default: true,          desc: 'force testing branch deletion using -D'
    option :pattern, type: 'string',  aliases: '-p', default: 'origin/XAP*', desc: 'specify a pattern for listing branches'
    option :verbose, type: 'boolean', aliases: '-v', default: false,         desc: 'display stdout on git commands, callstack on errors'
    def test
      master_branch, testing_branch = Ding::MASTER_BRANCH.dup, Ding::TESTING_BRANCH.dup
      say "\nDing ding ding: let's push a feature branch to #{testing_branch}...", :green

      repo = Ding::Git.new(options).tap do |r|
        say "\n> Synchronising with the remote...", :green
        r.checkout master_branch
        r.update
      end

      branches = repo.branches(options[:pattern])
      if branches.empty?
        say "\n --> No feature branches available to test, I'm out of here!\n\n", :red
        exit 1
      end

      feature_branch = ask_which_branch_to_test(branches)

      repo.tap do |r|
        say "\n> Deleting #{testing_branch}...", :green
        r.delete_branch(testing_branch)
        say "> Checking out #{feature_branch}...", :green
        r.checkout(feature_branch)
        say "> Creating #{testing_branch}...", :green
        r.create_branch(testing_branch)
        say "> Pushing #{testing_branch} to the remote...", :green
        r.push(testing_branch)
      end

    rescue => e
      say "\n  --> Error: #{e.message}\n\n", :red
      raise if options[:verbose]
      exit 1
    else
      say "\n  --> I'm finished: ding ding ding!\n\n", :green
    end

    default_task :test

    private

    def ask_which_branch_to_test(branches)
      return branches.first if branches.size == 1
      str_format = "\n %#{branches.count.to_s.size}s: %s"
      question   = set_color "\nWhich feature branch should I use?", :yellow
      answers    = {}

      branches.each_with_index do |branch, index|
        i = (index + 1).to_s
        answers[i] = branch
        question << format(str_format, i, branch)
      end

      say question
      reply = ask("> ").to_s
      if answers[reply]
        answers[reply]
      else
        say "\n  --> That's not a valid selection, I'm out of here!\n\n", :red
        exit 1
      end
    end
  end
end
