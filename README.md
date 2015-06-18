# Ding

![Ding](./ding.png)

Simple command line tool for deploying a specific feature branch of a
repo to a testing branch for driving CI deployment for QA.

## Installation

The usual method works:

    gem install ding

## Configuration

By default, `ding` will create a branch called `testing` from the
selected feature branch. It also assumes that the master branch is
called `master`. Branches named `master` and `develop` cannot be deleted
by calling `Ding::Git.delete_branch` in code.

These defaults can be over-ridden by providing ENV vars to the shell:

    DING_MASTER_BRANCH       - main branch to switch to for synchronising
    DING_TESTING_BRANCH      - branch to over-ride from feature branch
    DING_SACROSANCT_BRANCHES - space separated list of protected branches

## Using Ding

There are several commands available with global options for verbosity and forcing actions:

    Commands:
      ding help [COMMAND]  # Describe available commands or one specific command
      ding key-gen         # Create a new private/public key pair and associated ssh config
      ding key-show        # Copy a public ssh key signature to the system clipboard (use -v to also display the signature)
      ding test            # Push a feature branch to the testing branch (this is the default action)

    Options:
      -f, [--force], [--no-force]      # use the force on commands that allow it e.g. git push
      -v, [--verbose], [--no-verbose]  # show verbose output such as full callstack on errors

### ding test

This is the default action so running `ding` is the equivalent of `ding test`.

There is an option to specify the feature branch pattern to display for
selection of the code to be pushed to `testing`.

    $ ding help test

    Usage:
      ding test

    Options:
      -p, [--pattern=PATTERN]          # specify a pattern for listing branches
                                       # Default: origin/XAP*

    Push a feature branch to the testing branch

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
      -t, [--type=TYPE]                # type of key to create per -t option on ssh-keygen
                                       # Default: rsa

    Create a new private/public key pair and associated ssh config

### ding key-show

If the public key is needed again for pasting into the bitbucket.org config it can be
captured on the clipboard by running this command and selecting the appropriate key from
the list presented.

