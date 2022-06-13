require 'roda'
require 'tilt/erubi'
require 'json'
require 'message_bus'
require 'strscan' # Needed for Rack::Multipart::Parser

require_relative 'models'

module LilaShell
class App < Roda
  opts[:root] = File.dirname(__FILE__)
  opts[:check_dynamic_arity] = false
  opts[:check_arity] = :warn

  include LilaShell

  plugin :sessions,
    :secret=>ENV.delete('LILA_SHELL_SESSION_SECRET'),
    :key=>'lila_shell.session'

  MESSAGE_BUS = MessageBus::Instance.new
  MESSAGE_BUS.configure(:backend=>:memory)

  plugin :direct_call
  plugin :render, :escape=>true
  plugin :forme_route_csrf
  plugin :symbol_views
  plugin :message_bus, :message_bus=>MESSAGE_BUS
  plugin :request_aref, :raise
  plugin :public
  plugin :common_logger
  plugin :typecast_params
  alias tp typecast_params

  Forme.register_config(:mine, :base=>:default, :labeler=>:explicit, :wrapper=>:div)
  Forme.default_config = :mine

  plugin :error_handler do |e|
    puts e.class, e.message, e.backtrace
    view :content=>'<p>Oops, an error occurred</p>'
  end

  plugin :content_security_policy do |csp|
    csp.default_src :none
    csp.style_src :self
    csp.form_action :self
    csp.script_src :self
    csp.connect_src :self
    csp.base_uri :none
    csp.frame_ancestors :none
  end

  route do |r|
    r.public

    r.root do
      :manage
    end

    r.post 'user' do
      check_csrf!
      user = User.create(:name=>tp.nonempty_str!('name'))
      request.redirect '/'
    end

    r.on 'room' do
      r.is do
        r.get do
          r.redirect "/room/#{tp.pos_int!('room_id')}/#{tp.pos_int!('user_id')}"
        end

        r.post do
          check_csrf!
          room = Room.create(:name=>tp.nonempty_str!('name'))
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

        r.post do
          check_csrf!

          r.is "join" do
            MESSAGE_BUS.publish(@channel, {:join=>@user.name, :at=>Time.now.strftime('%H:%M:%S')}.to_json)
            ''
          end

          r.is "leave" do 
            MESSAGE_BUS.publish(@channel, {:leave=>@user.name, :at=>Time.now.strftime('%H:%M:%S')}.to_json)
            ''
          end

          r.is "message" do
            post = tp.str!('post').strip
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
end
