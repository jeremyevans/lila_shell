Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String :name, :unique=>true, :null=>false
    end

    create_table(:rooms) do
      primary_key :id
      String :name, :unique=>true, :null=>false
    end

    create_table(:messages) do
      primary_key :id
      foreign_key :user_id, :users, :null=>false
      foreign_key :room_id, :rooms, :null=>false
      Time :at, :null=>false, :default=>Sequel::CURRENT_TIMESTAMP
      String :message, :null=>false

      index [:room_id, Sequel.desc(:at)], :name=>:room_messages_idx
    end
  end
end
