# frozen_string_literal: true
require 'capybara'
require 'capybara/dsl'
require "capybara/cuprite"
require 'securerandom'
require 'puma/cli'
require 'nio'
require_relative 'minitest_helper'

ENV['RACK_ENV'] = 'test'
ENV['AJAX_TESTS'] = '1'
ENV['LILA_SHELL_DATABASE_URL'] ||= "postgres:///lila_shell_test?user=lila_shell"
ENV['LILA_SHELL_SESSION_SECRET'] ||= SecureRandom.base64(48)

require_relative '../lila_shell'

port = 3002
db_name = LilaShell::DB.get{current_database.function}
raise "Doesn't look like a test database (#{db_name}), not running tests" unless db_name =~ /test\z/

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [1200, 800], xvfb: true)
end
Capybara.current_driver = :cuprite
Capybara.default_selector = :css
Capybara.server_port = port
Capybara.exact = true

queue = Queue.new
server = Puma::CLI.new(['-s', '-b', "tcp://127.0.0.1:#{port}", '-t', '1:1', 'config.ru'])
server.launcher.events.on_booted{queue.push(nil)}
Thread.new do
  server.launcher.run
end
queue.pop

describe 'LilaShell' do
  include Capybara::DSL

  after do
    Capybara.reset_sessions!
  end

  around(:all) do |&block|
    LilaShell::DB.transaction(:rollback=>:always) do
      super(&block)
    end
  end

  around do |&block|
    LilaShell::DB.transaction(:rollback=>:always, :savepoint=>true, :auto_savepoint=>true) do |c|
      LilaShell::DB.temporarily_release_connection(c) do
        super(&block)
      end
    end
  end

  it "should work as expected" do
    visit("http://127.0.0.1:#{port}/")
    page.title.must_equal 'Lila Shell - Manage'

    fill_in 'User Name', :with=>'Foo'
    click_button 'Create User'

    fill_in 'Room Name', :with=>'Bar'
    click_button 'Create Room'

    select 'Foo'
    select 'Bar'
    click_button 'Join Room'

    page.title.must_equal 'Lila Shell - User: Foo, Room: Bar'
    page.find('#post').set('Test Post')
    click_button 'Post'
    visit page.current_url
    page.find('#posts').text.must_include 'Foo: Test Post'

    page.find('#post').set('Another Post')
    click_button 'Post'
    visit page.current_url
    page.find('#posts').text.must_include 'Foo: Another Post'
  end
end
