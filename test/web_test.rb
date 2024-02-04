# frozen_string_literal: true
require 'capybara'
require 'capybara/dsl'
require "capybara/cuprite"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [1200, 800], xvfb: true)
end
Capybara.current_driver = :cuprite
Capybara.default_selector = :css
Capybara.server_port = ENV['PORT'].to_i
Capybara.exact = true

require_relative 'minitest_helper'

begin
  require 'refrigerator'
rescue LoadError
else
  Refrigerator.freeze_core
end

describe 'LilaShell' do
  include Capybara::DSL

  after do
    Capybara.reset_sessions!
  end

  it "should work as expected" do
    visit("http://127.0.0.1:#{ENV['PORT']}/")
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
