require 'thor'

module Ding
  class Cli < Thor

    desc "test", "Push a feature branch to the testing branch"
    option :force,   type: 'boolean', aliases: '-f', default: true,          desc: 'force testing branch deletion using -D'
    option :pattern, type: 'string',  aliases: '-p', default: 'origin/XAP*', desc: 'specify a pattern for listing branches'
    option :verbose, type: 'boolean', aliases: '-v', default: false,         desc: 'display stdout on git commands, callstack on errors'
    def test
      say "\nDing ding ding: push a feature branch to #{Ding::TESTING_BRANCH}...", :green

      repo = Ding::Git.new(options).tap do |r|
        say " > Synchronise with the remote...", :green
        r.checkout Ding::MASTER_BRANCH
        r.update
      end

      branches = repo.branches
      if branches.empty?
        say "\n --> No feature branches available to test, I'm out of here!", :red
        exit 1
      end

      branch = ask_which_branch_to_test(branches)

      repo.tap do |r|
        say " > Delete #{Ding::TESTING_BRANCH}...", :green
        r.delete_branch(Ding::TESTING_BRANCH)
        say " > Checkout feature #{branch}...", :green
        r.checkout(branch)
        say " > Create #{Ding::TESTING_BRANCH}...", :green
        r.create_branch(Ding::TESTING_BRANCH)
        say " > Push #{Ding::TESTING_BRANCH} to the remote...", :green
        r.push(Ding::TESTING_BRANCH)
      end

    rescue => e
      say "\n --> Error: #{e.message}\n\n", :red
      raise if options[:verbose]
    else
      say "\n --> Finished!\n\n", :green
    end

    default_task :test

    private

    def ask_which_branch_to_test(branches)
      return branches.first if branches.size == 1
      str_format = "\n %#{branches.count.to_s.size}s: %s"
      question   = set_color "\nWhich branch should I use?", :yellow
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
        say "\nNot a valid selection, I'm out of here!", :red
        exit 1
      end
    end
  end
end
