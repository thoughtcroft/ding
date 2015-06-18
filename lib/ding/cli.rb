require 'shellwords'
require 'thor'

module Ding
  class Cli < Thor
    class_option :force,   type: 'boolean', aliases: '-f', default: false, desc: 'use the force on commands that allow it e.g. git push'
    class_option :verbose, type: 'boolean', aliases: '-v', default: false, desc: 'show verbose output such as full callstack on errors'

    default_task :test

    desc "test", "Push a feature branch to the testing branch (this is the default action)"
    option :pattern, type: 'string',  aliases: '-p', default: 'origin/XAP*', desc: 'specify a pattern for listing branches'
    def test
      master_branch, testing_branch = Ding::MASTER_BRANCH.dup, Ding::TESTING_BRANCH.dup
      say "\nDing ding ding: let's push a feature branch to #{testing_branch}...\n\n", :green

      repo = Ding::Git.new(options).tap do |r|
        say "> Synchronising with the remote...", :green
        r.checkout master_branch
        r.update
      end

      branches = repo.branches(options[:pattern])
      if branches.empty?
        say "\n --> No feature branches available to test, I'm out of here!\n\n", :red
        exit 1
      end

      feature_branch = ask_which_item(branches, 'Which feature branch should I use?')

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
      show_error e
    else
      say "\n  --> I'm finished: ding ding ding!\n\n", :green
    end

    desc "key-gen", "Create a new private/public key pair and associated ssh config"
    option :host,       type: 'string', aliases: '-h', default: 'bitbucket.org', desc: 'specify repository host for ssh config'
    option :name,       type: 'string', aliases: '-n', default: nil,             desc: 'name for key, defaults to host name'
    option :passphrase, type: 'string', aliases: '-p', default: '',              desc: 'optional passphrase for key'
    option :type,       type: 'string', aliases: '-t', default: 'rsa',           desc: 'type of key to create per -t option on ssh-keygen'
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
      say "\n  --> You can now Command-V to paste that key: ding ding ding!\n\n", :green
    end

    private

    def show_error(e)
      say "\n  --> Error: #{e.message}\n\n", :red
      raise if options[:verbose]
      exit 1
    end

    def ask_which_item(items, prompt)
      return items.first if items.size == 1
      str_format = "\n %#{items.count.to_s.size}s: %s"
      question   = set_color prompt, :yellow
      answers    = {}

      items.each_with_index do |item, index|
        i = (index + 1).to_s
        answers[i] = item
        question << format(str_format, i, item)
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
