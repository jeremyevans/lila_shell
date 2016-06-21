require 'roda'
require 'tilt/erubis'
require './models'
require 'json'

require 'message_bus'
#MessageBus.configure(:backend=>:postgres, :backend_options=>{:user=>'message_bus', :dbname=>'message_bus'})
MessageBus.configure(:backend=>:memory)

#MessageBus.subscribe "/room/1" do |msg|
#  p [:subscribe, msg]
#end

class LilaShell < Roda
  use Rack::CommonLogger

  plugin :render, :escape=>true
  plugin :forme
  plugin :symbol_views
  plugin :symbol_matchers
  plugin :message_bus

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
      r.get true do
        r.redirect "/room/#{r[:room_id]}/#{r[:user_id]}"
      end

      r.post true do
        room = Room.create(:name=>r['name'].to_s)
        r.redirect '/'
      end

      r.on ":d/:d" do |room_id, user_id|
        @user = User.with_pk!(user_id.to_i)
        @room = Room.with_pk!(room_id.to_i)
        @channel = "/room/#{@room.id}"
        
        next "No access" if @user.name == @room.name

        r.message_bus(@channel)

        r.get true do
          :room
        end

        r.post "join" do
          MessageBus.publish(@channel, {:join=>@user.name, :at=>Time.now.strftime('%H:%M:%S')}.to_json)
          ''
        end

        r.post "leave" do
          MessageBus.publish(@channel, {:leave=>@user.name, :at=>Time.now.strftime('%H:%M:%S')}.to_json)
          ''
        end

        r.post "message" do
          post = r[:post].to_s.strip
          unless post.empty?
            m = Message.create(:user_id=>@user.id, :room_id=>@room.id, :message=>post)
            MessageBus.publish(@channel, {:user=>m.user.name, :room_id=>@room.id, :message=>m.message, :at=>m.at.strftime('%H:%M:%S')}.to_json)
          end
          ''
        end
      end
    end
  end
end

