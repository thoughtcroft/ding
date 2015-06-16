# Ding

![Ding](./ding.png)

Simple command line tool for deploying a specific feature branch of a
repo to a testing branch for driving CI deployment for QA.

## Installation

Since this is a private gem (and perhaps it shouldn't be but it is) then
there are two ways to install it:

### Using Bundler

Add this line to your existing (or new) Gemfile:

```ruby
gem 'ding', :git => 'https://thoughtcroft@bitbucket.org/arisapp/ding.git'
```

Then run Bundler to install the gem:

    $ bundle install

### Clone this repo and install

    $ git clone https://thoughtcroft@bitbucket.org/arisapp/ding.git
    $ cd ding
    $ bundle exec rake install

## Configuration

By default, `ding` will create a branch called `testing` from the
selected feature branch. It also assumes that the master branch is
called `master`. Branches named `master` and `develop` cannot be deleted
by calling Ding::Git.delete_branch in code.

These defaults can be over-ridden by providing ENV vars to the shell:

    DING_MASTER_BRANCH       - main branch to switch to for synchronising
    DING_TESTING_BRANCH      - branch to over-ride from feature branch
    DING_SACROSANCT_BRANCHES - space separated list of protected branches

## Using Ding

There is currently only one command available: `test` which is the
default so it does not need to be used unless the following option is required.

There is an option to specify the feature branch pattern to display for
selection of the code to be pushed to `testing`.

    $ ding help test

    Usage:
      ding test

    Options:
      -p, [--pattern=PATTERN]  # specify a pattern for listing branches
                               # Default: XAP*

    Push a feature branch to the testing branch
