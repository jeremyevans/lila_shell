# Lila Shell

Lila Shell is a simple chat app that serves as an example of using
roda-message_bus.

## Demo

A demo site is available at http://lilashell-demo.jeremyevans.net

## Setup

The server is written in Ruby, so the first step is installing Ruby.

After installing Ruby, install the dependencies:

    gem install -g Gemfile

The server requires a PostgreSQL backend. It's recommended you set up an
application specific server and database, and you can use the bootstrap
rake task to do that (be sure to read it first to see what it does):

    rake bootstrap

You need to set the following enviroment variables:

LILA_SHELL\_DATABASE\_URL :: PostgreSQL database connection URL
LILA_SHELL_SESSION_CIPHER_SECRET :: session cipher secret, 32 bytes
LILA_SHELL_SESSION_HMAC_SECRET :: session HMAC secret, >=32 bytes

One way to set this is to create a .env.rb file in the root of the repository
containing:

    ENV['LILA_SHELL_DATABASE_URL'] ||= 'postgres:///?user=lila_shell&password=...'
    ENV['LILA_SHELL_SESSION_CIPHER_SECRET'] ||= '...'
    ENV['LILA_SHELL_SESSION_HMAC_SECRET'] ||= '...'

You can then run the server (via unicorn or another rack-compatible webserver):

    unicorn

## Tests

You can run all test suites using the default rake task:

    rake

For the web tests, you need to setup a test database, but the bootstrap task
described in the Setup section takes care of that.

## Source

The most current source code can be accessed via github
(http://github.com/jeremyevans/lila_shell).

## Author

Jeremy Evans (code@jeremyevans.net)
