require 'thor'

module Ding
  class Cli < Thor

    desc "test", "Deploy a feature branch to the testing branch"
    option :pattern, type: 'string', aliases: '-p', default: 'XAP*', desc: 'specify a pattern for listing branches'
    def test
      repo = Ding::Git.new.tap do |r|
        r.checkout Ding::MASTER_BRANCH
        r.delete_branch(Ding::TESTING_BRANCH)
        r.update
      end

      branch = ask_which_branch_to_test(repo.branches(options[:pattern]))
      repo.tap do |r|
        r.checkout(branch)
        r.create(Ding::TESTING_BRANCH)
        r.push(Ding::TESTING_BRANCH)
      end

      say "\n\n ---> Finished!\n\n", :green
    end

    default_task :test

    private

    def ask_which_branch_to_test(branches)
      return branches.first if branches.size == 1
      str_format = "\n %#{branches.count.to_s.size}s: %s"
      question   = set_color "\nWhich branch should I use?", :yellow
      answers    = {}

      branches.sort.each_with_index do |branch, index|
        i = (index + 1).to_s
        answers[i] = branch
        question << format(str_format, i, branch)
      end

      puts question
      reply = ask("> ").to_s
      if answers[reply]
        answers[reply]
      else
        say "Not a valid selection, I'm out of here!", :red
        exit 1
      end
    end

  end
end
