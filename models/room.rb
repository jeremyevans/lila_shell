class Room < Sequel::Model
  one_to_many :messages, :order=>Sequel.desc(:at), :eager=>:user
  one_to_many :recent_messages, :clone=>:messages, :limit=>50
end
