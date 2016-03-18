require 'ding/version'
require 'ding/cli'
require 'ding/helpers'
require 'ding/models/git'
require 'ding/models/ssh'

module Ding
  MASTER_BRANCH       = ENV['DING_MASTER_BRANCH']  || 'master'
  DEVELOP_BRANCH      = ENV['DING_DEVELOP_BRANCH'] || 'develop'
  TESTING_BRANCH      = ENV['DING_TESTING_BRANCH'] || 'testing'
  SACROSANCT_BRANCHES = (ENV['DING_SACROSANCT_BRANCHES'] || "#{MASTER_BRANCH} #{DEVELOP_BRANCH}").split

  # because we lurve the command line... ding!
end
