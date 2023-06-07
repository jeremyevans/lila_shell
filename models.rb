# frozen_string_literal: true
require_relative 'db'
require 'sequel'

module LilaShell
  Model = Class.new(Sequel::Model)
  Model.db = DB
  Model.def_Model(self)

  Model.plugin :subclasses
  Model.plugin :auto_validations, :not_null=>:presence

  require_relative 'models/message'
  require_relative 'models/room'
  require_relative 'models/user'
end
