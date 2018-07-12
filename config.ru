require './lila_shell'
run LilaShell::App.freeze.app

begin
  require 'refrigerator'
rescue LoadError
else
  Refrigerator.freeze_core(:except=>['BasicObject'])
end
