require 'ding/version'
require 'ding/cli'
require 'ding/models/git'

module Ding
  MASTER_BRANCH  = ENV['DING_MASTER_BRANCH'] || 'master'
  TESTING_BRANCH = ENV['DING_TESTING_BRANCH'] || 'testing'
  SACROSANCT_BRANCHES = (ENV['DING_SACROSANCT_BRANCHES'] || 'master develop').split

  # because we lurve the command line...
end
