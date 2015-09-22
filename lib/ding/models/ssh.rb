require 'fileutils'

module Ding
  class Ssh
    include Ding::Helpers

    attr_reader :options

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
      raise "ssh key #{name} does not exist!" if ssh_key_exists? name
      File.delete ssh_public_key_file(name), ssh_private_key_file(name)
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
        f.puts "  StrictHostKeyChecking no" if options[:secure_host]
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
  end
end
