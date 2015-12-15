require 'shellwords'
require 'thor'

module Ding
  class Cli < Thor
    class_option :force,   type: 'boolean', aliases: '-f', default: true,  desc: 'use the force on commands that allow it e.g. git push'
    class_option :verbose, type: 'boolean', aliases: '-v', default: false, desc: 'show verbose output such as full callstack on errors'

    default_task :push

    desc "push", "Push feature branch(es) to the testing branch (this is the default action)"
    option :branch,  type: 'string',  aliases: '-b', default: nil,           desc: 'specify an over-ride destination branch'
    option :local,   type: 'boolean', aliases: '-l', default: false,         desc: 'operate on local branches (merged from remote)'
    option :merged,  type: 'boolean', aliases: '-m', default: false,         desc: 'only display branches that have been merged'
    option :pattern, type: 'string',  aliases: '-p', default: '*XAP*',       desc: 'specify a pattern for listing branches'
    def push
      testing_branch = options[:branch] || Ding::TESTING_BRANCH.dup

      say "\nDing ding ding: let's merge one or more feature branches to #{testing_branch}:\n\n", :green

      repo = Ding::Git.new(options).tap do |r|
        if r.is_dirty?
          say "> Local repo is dirty, resetting state", :yellow
          r.reset_local_state
        end

        develop_branch = r.branch_in_context(Ding::DEVELOP_BRANCH.dup)
        r.checkout develop_branch

        say "> Deleting #{testing_branch}", :green
        r.delete_branch(testing_branch)

        say "> Synchronising with the remote", :green
        r.update
      end

      branches = repo.remote_branches(options[:pattern])
      if branches.empty?
        say "\n --> No feature branches available to test, I'm out of here!\n\n", :red
        exit 1
      end

      feature_branches = ask_which_item(branches, "\nWhich feature branch should I use?", :multiple)

      repo.tap do |r|
        say "\n> Deleting any synched #{testing_branch}", :green
        r.delete_branch(testing_branch)

        say "> Creating #{testing_branch}", :green
        r.create_branch(testing_branch)

        say "> Merging in selected feature #{feature_branches.count == 1 ? 'branch' : 'branches'}...", :green
        merge_errors = false
        feature_branches.each do |branch|
          if r.merge_branch(branch)
            say "   ✓  #{branch}", :green
          else
            say "   ✗  #{branch}", :red
            merge_errors = true
          end
        end

        unless merge_errors
          say "> Pushing #{testing_branch} to the remote", :green
          r.push(testing_branch)
        else
          say "\n  --> There were merge errors, ding dang it!\n\n", :red
          exit 1
        end
      end

    rescue => e
      show_error e
    else
      say "\n  --> I'm finished: ding ding ding!\n\n", :green
      exit 0
    end

    desc "version", "Display current version of 'ding'"
    def version
      say "ding #{Ding::VERSION}\n"
    end

    desc "key-gen", "Create a new private/public key pair and associated ssh config"
    option :host,       type: 'string',  aliases: '-h', default: 'bitbucket.org', desc: 'specify repository host for ssh config'
    option :name,       type: 'string',  aliases: '-n', default: nil,             desc: 'name for key, defaults to host name'
    option :passphrase, type: 'string',  aliases: '-p', default: '',              desc: 'optional passphrase for key'
    option :secure,     type: 'boolean', aliases: '-s', default: true,            desc: 'secure hosts do not need strict host key checking'
    option :type,       type: 'string',  aliases: '-t', default: 'rsa',           desc: 'type of key to create per -t option on ssh-keygen'
    def key_gen
      key_name = options[:name] || "#{options[:host]}_#{options[:type]}"
      say "\nDing ding ding: let's create and configure a new ssh key #{key_name}:\n\n", :green

      Ding::Ssh.new(options).tap do |s|
        if s.ssh_key_exists?(key_name)
          if yes?("Do you want me to replace the existing key?", :yellow)
            say "> Removing existing key #{key_name}", :cyan
            s.delete_ssh_key key_name

            say "> Creating the replacement ssh key pair", :cyan
            s.create_ssh_key key_name, ENV['USER']
          else
            say "> Using existing key #{key_name}", :cyan
          end
        else
          say "> Creating the new ssh key pair", :green
          s.create_ssh_key key_name, ENV['USER']
        end
        say "> Adding the private key to the ssh config", :green
        s.update_config options[:host], key_name

        say "> Copying the public key to the clipboard", :green
        copy_file_to_clipboard s.ssh_public_key_file(key_name)
      end

    rescue => e
      show_error e
    else
      say "\n  --> I'm finished: ding ding ding!\n\n", :green
      exit 0
    end

    desc "key-show", "Copy a public ssh key signature to the system clipboard (use -v to also display the signature)"
    def key_show
      say "\nDing ding ding: let's copy a public key to the clipboard:\n\n", :green

      Ding::Ssh.new(options).tap do |s|
        key_name = ask_which_item(s.list_ssh_keys, "Which key do you want to copy?")
        say "\n> Copying the public key to the clipboard", :green
        copy_file_to_clipboard s.ssh_public_key_file(key_name)
      end

    rescue => e
      show_error e
    else
      say "\n  --> You can now Command-v to paste that key: ding ding ding!\n\n", :green
      exit 0
    end

    private

    def show_error(e)
      say "\n  --> ERROR: #{e.message}\n\n", :red
      raise if options[:verbose]
      exit 1
    end

    # presents a list of choices and allows either a single or multiple selection
    # returns the selected choices in an array or exits if selection is invalid
    def ask_which_item(items, prompt, mode=:single)
      return Array(items.first) if items.size == 1
      str_format = "\n %#{items.count.to_s.size}s: %s"
      prompt << "\n > Enter a single selection, "
      prompt << "multiple selections separated by ',', 'A' for all, " if mode == :multiple
      prompt << "'Q' or nothing to quit"
      question   = set_color prompt, :yellow
      answers    = {}

      items.each_with_index do |item, index|
        i = (index + 1).to_s
        answers[i] = item
        question << format(str_format, i, item)
      end

      say question
      reply = ask(" >", :yellow).to_s
      replies = reply.split(',')
      if reply.empty? || reply.upcase == 'Q'
        say "\n --> OK, nothing for me to do here but ding ding ding!\n\n", :green
        exit 0
      elsif answers[reply]
        answers.values_at(reply)
      elsif mode == :single
          say "\n  --> That's not a valid selection, I'm out of here!\n\n", :red
          exit 1
      elsif mode == :multiple && reply.upcase == 'A'
        answers.values
      elsif mode == :multiple && !replies.empty?
        selected_items = answers.values_at(*replies)
        if selected_items.include?(nil)
          say "\n  --> That's not a valid selection, I'm out of here!\n\n", :red
          exit 1
        end
        selected_items
      end
    end

    def copy_file_to_clipboard(file)
      cmd = "cat #{file}"
      cmd << (options[:verbose] ? '|tee >(pbcopy)' : '|pbcopy')
      bash cmd
    end

    def bash(cmd)
      escaped_cmd = Shellwords.escape cmd
      system "bash -c #{escaped_cmd}"
    end
  end
end
