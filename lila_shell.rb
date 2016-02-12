require 'roda'
require 'tilt/erubis'
require './models'
require 'json'

class LilaShell < Roda
  MUTEX = Mutex.new
  LISTENERS = {}
  Thread.new do
    DB.listen('room', :loop=>true) do |_,_,data|
begin
      room_id = JSON.parse(data)['room_id']
      listeners = MUTEX.synchronize{(LISTENERS[room_id] || []).dup}
      listeners.each do |ws|
        ws.send(data)
      end
rescue
    puts e.class, e.message, e.backtrace
end
    end
  end

  if defined?(Reel)
    class RodaRequest
      require 'reel/websocket'
      class WebSocket < ::Reel::WebSocket
        def self.websocket?(env)
          ::WebSocket::Driver.websocket?(env) && !!env['reel.request']
        end

        def initialize(env, options={})
          @ws = env['reel.request'].websocket
        end

        def on(meth, &block)
          @ws.public_send("on_#{meth}", &block)
        end

        def rack_response
          [ 101, {}, [] ]
        end

        def send(s)
          @ws.write(s)
        end
      end
    end
  else
    plugin :websockets, :adapter=>:thin
  end

  def sync
   MUTEX.synchronize{yield}
  end

  plugin :static, %w'/index.html'
  plugin :render, :escape=>true
  plugin :forme
  plugin :symbol_views
  plugin :symbol_matchers

  plugin :error_handler do |e|
    puts e.class, e.message, e.backtrace
    view :content=>'<p>Oops, an error occurred</p>'
  end

  route do |r|
    r.root do
      :manage
    end

    r.post do
      r.is 'user' do
        user = User.create(:name=>r['name'].to_s)
        r.redirect '/'
      end

      r.is 'room' do
        room = Room.create(:name=>r['name'].to_s)
        r.redirect '/'
      end
    end

    r.get 'join' do
      user = @user = User.with_pk!(r['user_id'].to_i)
      room = @room = Room.with_pk!(r['room_id'].to_i)
      user_id = user.id
      user_name = user.name
      room_id = room.id

      r.websocket do |ws|
        sync{(LISTENERS[room_id] ||= []) << ws}
        data = {:join=>user_name, :room_id=>room_id, :at=>Time.now.strftime('%H:%M:%S')}.to_json
        DB.notify('room', :payload=>data)

        ws.on :message do |event|
          str = event.is_a?(String) ? event : event.data
          next if str.empty?

          DB.transaction do
            m = Message.create(:user_id=>user_id, :room_id=>room_id, :message=>str)
            data = {:user=>user_name, :room_id=>room_id, :message=>str, :at=>m.at.strftime('%H:%M:%S')}.to_json
            DB.notify('room', :payload=>data)
          end
        end

        ws.on :close do |event|
          sync{(LISTENERS[room_id] || []).delete(ws)}
          data = {:leave=>user_name, :room_id=>room_id, :at=>Time.now.strftime('%H:%M:%S')}.to_json
          DB.notify('room', :payload=>data)
        end
      end

      :room
    end
  end
end

