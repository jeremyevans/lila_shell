# frozen_string_literal: true
begin
  require_relative '.env.rb'
rescue LoadError
end

require 'sequel/core'

module LilaShell
  opts = {}
  opts[:max_connections] = 1 if ENV['AJAX_TESTS'] == '1'
  DB = Sequel.connect(ENV.delete('LILA_SHELL_DATABASE_URL') || ENV.delete('DATABASE_URL'), opts)
  DB.extension :pg_auto_parameterize
  if ENV['AJAX_TESTS'] == '1'
    DB.extension :temporarily_release_connection
  end
end
