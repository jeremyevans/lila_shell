begin
  require_relative '.env.rb'
rescue LoadError
end

require 'sequel/core'

module LilaShell
  DB = Sequel.connect(ENV.delete('LILA_SHELL_DATABASE_URL') || ENV.delete('DATABASE_URL'))
end
