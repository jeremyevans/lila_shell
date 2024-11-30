# frozen_string_literal: true
require_relative 'models'

require 'roda'
require 'json'
require 'message_bus'
require 'strscan' # Needed for Rack::Multipart::Parser

require 'tilt'
require 'tilt/erubi'

module LilaShell
class App < Roda
  def self.freeze
    Model.freeze_descendents
    DB.freeze
    super
  end

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
  plugin :render, :escape=>true, :template_opts=>{:chain_appends=>true, :freeze=>true, :skip_compiled_encoding_detection=>true}
  plugin :forme_route_csrf
  plugin :symbol_views
  plugin :message_bus, :message_bus=>MESSAGE_BUS
  plugin :request_aref, :raise
  plugin :public
  plugin :disallow_file_uploads
  plugin :typecast_params_sized_integers, :sizes=>[64], :default_size=>64
  plugin :Integer_matcher_max
  alias tp typecast_params

  logger = if ENV['RACK_ENV'] == "test"
    Class.new{def write(_) end}.new
  else
    $stderr
  end
  plugin :common_logger, logger

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
      User.create(:name=>tp.nonempty_str!('name'))
      request.redirect '/'
    end

    r.on 'room' do
      r.is do
        r.get do
          r.redirect "/room/#{tp.pos_int!('room_id')}/#{tp.pos_int!('user_id')}"
        end

        r.post do
          check_csrf!
          Room.create(:name=>tp.nonempty_str!('name'))
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
