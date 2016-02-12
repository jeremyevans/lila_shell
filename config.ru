require './lila_shell'
use Rack::Lint
class Rack::Lint::HijackWrapper
  def to_int
    @io.to_i
  end
end
run LilaShell.freeze.app
