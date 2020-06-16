require_relative 'warnings_helper'
require_relative 'minitest_helper'

ENV['RACK_ENV'] = 'test'
require_relative '../models'

include LilaShell
raise "test database must end with test" unless DB.get{current_database.function}.end_with?('test')

describe Message do
  it "#line should return the line to display in the chat room" do
    m = Message.new(:user=>User.load(:id=>1, :name=>'foo'), :message=>'bar', :at=>Time.local(2018, 10, 11, 13, 14, 15))
    m.line.must_equal "<13:14:15> foo: bar"
  end
end
