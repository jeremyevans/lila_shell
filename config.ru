require './lila_shell'
run LilaShell::App.freeze.app

if ENV['RACK_ENV'] != 'development'
  begin
    require 'refrigerator'
  rescue LoadError
  else
    Refrigerator.freeze_core(:except=>['BasicObject'])
  end
end
