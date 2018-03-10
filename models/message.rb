module LilaShell
class Message < Model
  many_to_one :user

  def line
    "<#{at.strftime('%H:%M:%S')}> #{user.name}: #{message}"
  end
end
end
