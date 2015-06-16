# Ding

Simple command line tool for deploying a specific feature branch of a
repo to a testing branch for driving CI deployment for QA purposes.

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

