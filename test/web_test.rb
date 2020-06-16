require 'capybara'
require 'capybara/dsl'
require_relative 'warnings_helper'
require_relative 'minitest_helper'

case ENV['CAPYBARA_DRIVER']
when 'chrome'
  puts "testing using chrome"
  require 'selenium-webdriver'
  Capybara.register_driver :chrome do |app|
    Capybara::Selenium::Driver.new app, browser: :chrome, options: Selenium::WebDriver::Chrome::Options.new(args: %w[headless disable-gpu])
  end

  Capybara.current_driver = :chrome
when 'firefox'
  puts "testing using firefox"
  require 'selenium-webdriver'
  Capybara.register_driver :firefox do |app|
    browser_options = Selenium::WebDriver::Firefox::Options.new
    browser_options.args << '--headless'
    Capybara::Selenium::Driver.new(app, browser: :firefox, marionette: true, options: browser_options)
  end
  Capybara.current_driver = :firefox
else
  puts "testing using capybara-webkit"
  require 'capybara-webkit'
  require 'headless'
  use_headless = true
  Capybara.current_driver = :webkit
  Capybara::Webkit.configure do |config|
    config.block_unknown_urls
  end
end
Capybara.default_selector = :css
Capybara.server_port = ENV['PORT'].to_i
Capybara.configure do |config|
  config.match = :prefer_exact
end

begin
  require 'refrigerator'
rescue LoadError
else
  Refrigerator.freeze_core(:except=>['BasicObject'])
end

describe 'LilaShell' do
  include Capybara::DSL

  if use_headless
    around do |&block|
      Headless.ly{super(&block)}
    end
  end

  after do
    Capybara.reset_sessions!
  end

  it "should work as expected" do
    visit('http://127.0.0.1:3001/')
    page.title.must_equal 'Lila Shell - Manage'

    fill_in 'User Name', :with=>'Foo'
    click_button 'Create User'

    fill_in 'Room Name', :with=>'Bar'
    click_button 'Create Room'

    select 'Foo'
    select 'Bar'
    click_button 'Join Room'

    page.title.must_equal 'Lila Shell - User: Foo, Room: Bar'
    sleep 0.5
    page.find('#post').set('Test Post')
    click_button 'Post'
    sleep 0.5
    page.find('#posts').text.must_include 'Foo: Test Post'

    page.find('#post').set('Another Post')
    click_button 'Post'
    sleep 0.5
    page.find('#posts').text.must_include 'Foo: Another Post'
  end
end
