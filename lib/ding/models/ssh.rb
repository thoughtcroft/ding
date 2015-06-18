require 'fileutils'

module Ding
  class Ssh

    def initialize(options={})
      @options = options
    end

    def list_ssh_keys
      Dir.glob(File.join(ssh_config_path, '*.pub')).map {|f| File.basename f, '.pub'}
    end

    def create_ssh_key(name, comment)
      raise "ssh key #{name} already exists!" if ssh_key_exists? name
      run_cmd "ssh-keygen -t #{options[:type]} -C #{comment} -P '#{options[:passphrase]}' -f #{File.join(ssh_config_path, name)}"
    end

    def delete_ssh_key(name)
      File.delete ssh_public_key_file(name), ssh_private_key_file(name) if ssh_key_exists? name
    end

    def update_config(host, name)
      if File.exists?(ssh_config_file)
        config = File.open(ssh_config_file).read
        raise "Host #{host} already configured in ssh config" if config.include?(host)
        raise "Key #{name} already configured in ssh config" if config.include?(name)
      else
        FileUtils.mkdir_p ssh_config_path
      end

      File.open(ssh_config_file, 'a') do |f|
        f.puts "Host #{host}"
        f.puts "  IdentityFile #{ssh_private_key_file name}"
      end
    end

    def ssh_key_exists?(name)
      File.exists? ssh_private_key_file(name)
    end

    def ssh_private_key_file(name)
      File.join ssh_config_path, name
    end

    def ssh_public_key_file(name)
      "#{ssh_private_key_file name}.pub"
    end

    private

    def ssh_config_exists?
      File.exists? ssh_config_file
    end

    def ssh_config_path
      @ssh_config_path || options[:ssh_config_path] || File.join(ENV['HOME'], '.ssh')
    end

    def ssh_config_file
      @ssh_config_file || options[:ssh_config_file] || File.join(ssh_config_path, 'config')
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
