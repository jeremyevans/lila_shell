require './db'

Sequel::Model.plugin :prepared_statements
Sequel::Model.plugin :auto_validations

Dir['./models/*.rb'].each{|f| require(f)}
