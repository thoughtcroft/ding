require 'shellwords'
require 'thor'

module Ding
  class Cli < Thor
    class_option :force,   type: 'boolean', aliases: '-f', default: true,  desc: 'use the force on commands that allow it e.g. git push'
    class_option :verbose, type: 'boolean', aliases: '-v', default: false, desc: 'show verbose output such as full callstack on errors'

    default_task :test

    desc "test", "Push a feature branch(es) to the testing branch (this is the default action)"
    option :merged,  type: 'boolean',  aliases: '-m', default: false,         desc: 'display branches that have been merged'
    option :pattern, type: 'string',   aliases: '-p', default: 'origin/XAP*', desc: 'specify a pattern for listing branches'
    def test
      develop_branch, testing_branch = Ding::DEVELOP_BRANCH.dup, Ding::TESTING_BRANCH.dup
      say "\nDing ding ding: let's merge one or more feature branches to #{testing_branch}...\n\n", :green

      repo = Ding::Git.new(options).tap do |r|
        say "> Synchronising with the remote...", :green
        r.checkout develop_branch
        r.update
      end

      branches = repo.branches(options[:pattern])
      if branches.empty?
        say "\n --> No feature branches available to test, I'm out of here!\n\n", :red
        exit 1
      end

      feature_branches = ask_which_item(branches, 'Which feature branch should I use?', :multiple)

      repo.tap do |r|
        say "\n> Deleting #{testing_branch}...", :green
        r.delete_branch(testing_branch)

        say "> Checking out #{develop_branch}...", :green
        r.checkout(develop_branch)

        say "> Creating #{testing_branch}...", :green
        r.create_branch(testing_branch)

        say "> Checking out #{testing_branch}...", :green
        r.checkout(testing_branch)

        say "> Merging in selected feature #{feature_branches.count == 1 ? 'branch' : 'branches'}...", :green
        merge_errors = false
        feature_branches.each do |branch|
          if r.merge_branch(branch)
            say ">>> #{branch} succeeded", :green
          else
            say ">>> #{branch} failed", :red
            merge_errors = true
          end
        end

        unless merge_errors
          say "> Pushing #{testing_branch} to the remote...", :green
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
    end

    desc "key-gen", "Create a new private/public key pair and associated ssh config"
    option :host,       type: 'string',  aliases: '-h', default: 'bitbucket.org', desc: 'specify repository host for ssh config'
    option :name,       type: 'string',  aliases: '-n', default: nil,             desc: 'name for key, defaults to host name'
    option :passphrase, type: 'string',  aliases: '-p', default: '',              desc: 'optional passphrase for key'
    option :secure,     type: 'boolean', aliases: '-s', default: true,            desc: 'secure hosts do not need strict host key checking'
    option :type,       type: 'string',  aliases: '-t', default: 'rsa',           desc: 'type of key to create per -t option on ssh-keygen'
    def key_gen
      key_name = options[:name] || "#{options[:host]}_#{options[:type]}"
      say "\nDing ding ding: let's create and configure a new ssh key #{key_name}...\n\n", :green

      Ding::Ssh.new(options).tap do |s|
        if s.ssh_key_exists?(key_name)
          if yes?("Do you want me to replace the existing key?", :yellow)
            say "> Removing existing key #{key_name}...", :cyan
            s.delete_ssh_key key_name
            say "> Creating the replacement ssh key pair...", :cyan
            s.create_ssh_key key_name, ENV['USER']
          else
            say "> Using existing key #{key_name}...", :cyan
          end
        else
          say "> Creating the new ssh key pair...", :green
          s.create_ssh_key key_name, ENV['USER']
        end
        say "> Adding the private key to the ssh config...", :green
        s.update_config options[:host], key_name
        say "> Copying the public key to the clipboard...", :green
        copy_file_to_clipboard s.ssh_public_key_file(key_name)
      end

    rescue => e
      show_error e
    else
      say "\n  --> I'm finished: ding ding ding!\n\n", :green
    end

    desc "key-show", "Copy a public ssh key signature to the system clipboard (use -v to also display the signature)"
    def key_show
      say "\nDing ding ding: let's copy a public key to the clipboard...\n\n", :green

      Ding::Ssh.new(options).tap do |s|
        key_name = ask_which_item(s.list_ssh_keys, 'Which key do you want to copy?')
        say "\n> Copying the public key to the clipboard...", :green
        copy_file_to_clipboard s.ssh_public_key_file(key_name)
      end

    rescue => e
      show_error e
    else
      say "\n  --> You can now Command-v to paste that key: ding ding ding!\n\n", :green
    end

    private

    def show_error(e)
      say "\n  --> ERROR: #{e.message}\n\n", :red
      raise if options[:verbose]
      exit 1
    end

    # presents a list of choices and allows either a single or multiple selection
    # returns the selected choices in an array or exist if selection is invalid
    def ask_which_item(items, prompt, mode=:single)
      return Array(items.first) if items.size == 1
      str_format = "\n %#{items.count.to_s.size}s: %s"
      prompt     = prompt << "\n > Enter multiple selections separated by ',' or 'A' for all" if mode == :multiple
      question   = set_color prompt, :yellow
      answers    = {}

      items.each_with_index do |item, index|
        i = (index + 1).to_s
        answers[i] = item
        question << format(str_format, i, item)
      end

      say question
      reply = ask(" >", :yellow).to_s
      begin
        replies = reply.split(',')
        if answers[reply]
          answers.values_at(reply)
        elsif mode == :multiple && reply == 'A'
          answers.values
        elsif mode == :multiple && !replies.empty?
          selected_items = answers.values_at(*replies)
          raise "Invalid selection" if selected_items.include?(nil)
          selected_items
        end
      rescue
        raise if options[:verbose]
        say "\n  --> That's not a valid selection, I'm out of here!\n\n", :red
        exit 1
      end
    end

    def copy_file_to_clipboard(file)
      cmd = "cat #{file} | "
      if options[:verbose]
        cmd << 'tee >(pbcopy)'
      else
        cmd << ' pbcopy'
      end
      bash cmd
    end

    def bash(cmd)
      escaped_cmd = Shellwords.escape cmd
      system "bash -c #{escaped_cmd}"
    end
  end
end
