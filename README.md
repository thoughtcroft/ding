# Ding

![Ding](./ding.png)

Simple command line tool for deploying a specific feature branch of a
repo to a testing branch for driving CI deployment for QA.

## Installation

Since we are installing from a private repository, we can't use the
usual `gem install ding` method. But don't worry, we have rake tasks for
that!

    cd <my_stuff>
    git clone git@bitbucket.org:arisapp/ding.git
    cd ding
    rake

You will of course require access to the Zunos Bitbucket account but
then that's what you want ding for anyway, right? So, sorted.

## Updates

From time to time, the software may change and you will want to update
ding. Well, there is a rake task for that too!

    cd <my_stuff>/ding
    rake update

Note that if you have uncommitted changes (you are a dev I hope) then
the update will halt and warn you of it.

## Configuration

By default, `ding` will create a branch called `testing` from the
selected feature branch. It also assumes that the master branch is
called `master` and the main development branch is called `develop`.
These main branches cannot be deleted using `Ding::Git.delete_branch`.

These defaults can be over-ridden by providing ENV vars to the shell:

    DING_MASTER_BRANCH       - main branch to switch to for synchronising
    DING_DEVELOP_BRANCH      - used to compare merge against feature
    DING_TESTING_BRANCH      - branch to over-ride 'testing' branch
    DING_SACROSANCT_BRANCHES - space separated list of protected branches

The testing branch can also be over-ridden by passing the `-b` option.

## Using Ding

There are several commands available with global options for verbosity and forcing actions:

    Commands:
      ding help [COMMAND]  # Describe available commands or one specific command
      ding key-gen         # Create a new private/public key pair and associated ssh config
      ding key-show        # Copy a public ssh key signature to the system clipboard (use -v to also display the signature)
      ding push            # Push a feature branch to the testing branch (this is the default action)
      ding version         # Display current gem version

    Options:
      -f, [--force], [--no-force]      # use the force on commands that allow it e.g. git push
      -v, [--verbose], [--no-verbose]  # show verbose output such as full callstack on errors

### ding push

This is the default action so running `ding` is the equivalent of `ding push`.

There is an option to specify the feature branch pattern to display for
selection of the code to be pushed to `testing`. By default, only
remote branches that haven't already been merged to `develop` will be
listed, this can be over-ridden by using the `-m` flag.

    $ ding help push

    Usage:
      ding push

    Options:
      -b, [--branch=BRANCH]            # specify an over-ride for the testingbranch
      -l, [--local], [--no-local]      # operate on local branches (merged from remote)
      -m, [--merged], [--no-merged]    # display branches that have been merged
      -p, [--pattern=PATTERN]          # specify a pattern for listing feature branches
                                       # Default: *XAP*
      -s, [--skip], [--no-skip]        # skip feature branch selection; just push develop to testing
      -f, [--force]                    # use the force on commands that allow it e.g. git push
                                       # Default: true
      -v, [--verbose], [--no-verbose]  # show verbose output such as full callstack on errors

    Push feature branch(es) to the testing branch (this is the default action)

The destination branch is selected in the following order:

1. The branch specified by the `-b` option
1. The branch specified in `ENV['DING_TESTING_BRANCH']`
1. Otherwise defaults to the `testing` branch

### ding key-gen

This will generate a new ssh key pair and configure them into the ssh config
for the relevant host. This allows `ding test` to push code to bitbucket.org,
for example, so that you aren't prompted for a userid and password each
time.

On completion, the public key is copied to the system clipboard so that
it can be pasted into the users account on bitbucket.org.

    Usage:
      ding key-gen

    Options:
      -h, [--host=HOST]                # specify repository host for ssh config
                                       # Default: bitbucket.org
      -n, [--name=NAME]                # name for key, defaults to host name
      -p, [--passphrase=PASSPHRASE]    # optional passphrase for key
      -s, [--secure], [--no-secure]    # secure hosts do not need strict host key checking
      -t, [--type=TYPE]                # type of key to create per -t option on ssh-keygen
                                       # Default: rsa

    Create a new private/public key pair and associated ssh config

### ding key-show

If the public key is needed again for pasting into the bitbucket.org config it can be
captured on the clipboard by running this command and selecting the appropriate key from
the list presented.

## Contributing

If you need to make a change to ding then follow these steps:

  1. Clone this repository (if you are not a current user)
  1. Base your commits on the master branch
  1. Update to the next version in `lib\ding\version.rb` using [SemVer](http://semver.org/)
  1. Use the rake tasks - see `rake -T` - to install the new version
  1. When you are ready to release, use the `rake release` task to tag and push

Good luck!

(PS if you get stuck, reach out to warren@thoughtcroft.com)
