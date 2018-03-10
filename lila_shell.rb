require 'roda'
require 'tilt/erubi'
require 'json'
require 'message_bus'

require_relative 'models'

module LilaShell
class App < Roda
  include LilaShell

  use Rack::CommonLogger

  MESSAGE_BUS = MessageBus::Instance.new
  MESSAGE_BUS.configure(:backend=>:memory)

  plugin :render, :escape=>true
  plugin :forme
  plugin :symbol_views
  plugin :symbol_matchers
  plugin :message_bus, :message_bus=>MESSAGE_BUS

  plugin :error_handler do |e|
    puts e.class, e.message, e.backtrace
    view :content=>'<p>Oops, an error occurred</p>'
  end

  route do |r|
    r.root do
      :manage
    end

    r.get 'message-bus.js' do
      File.read 'public/message-bus.js'
    end

    r.post 'user' do
      user = User.create(:name=>r['name'].to_s)
      r.redirect '/'
    end

    r.on 'room' do
      r.is do
        r.get do
          r.redirect "/room/#{r[:room_id]}/#{r[:user_id]}"
        end

        r.post do
          room = Room.create(:name=>r['name'].to_s)
          r.redirect '/'
        end
      end

      r.on Integer, Integer do |room_id, user_id|
        @user = User.with_pk!(user_id)
        @room = Room.with_pk!(room_id)
        @channel = "/room/#{@room.id}"
        
        next "No access" if @user.name == @room.name

        r.message_bus(@channel)

        r.get true do
          :room
        end

        r.post "join" do
          MESSAGE_BUS.publish(@channel, {:join=>@user.name, :at=>Time.now.strftime('%H:%M:%S')}.to_json)
          ''
        end

        r.post "leave" do
          MESSAGE_BUS.publish(@channel, {:leave=>@user.name, :at=>Time.now.strftime('%H:%M:%S')}.to_json)
          ''
        end

        r.post "message" do
          post = r[:post].to_s.strip
          unless post.empty?
            m = Message.create(:user_id=>@user.id, :room_id=>@room.id, :message=>post)
            MESSAGE_BUS.publish(@channel, {:user=>m.user.name, :room_id=>@room.id, :message=>m.message, :at=>m.at.strftime('%H:%M:%S')}.to_json)
          end
          ''
        end
      end
    end
  end
end
end
