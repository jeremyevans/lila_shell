# frozen_string_literal: true
module LilaShell
class Message < Model
  many_to_one :user

  def line
    "<#{at.strftime('%H:%M:%S')}> #{user.name}: #{message}"
  end
end
end

# Table: messages
# Columns:
#  id      | integer                     | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  user_id | integer                     | NOT NULL
#  room_id | integer                     | NOT NULL
#  at      | timestamp without time zone | NOT NULL DEFAULT now()
#  message | text                        | NOT NULL
# Indexes:
#  messages_pkey     | PRIMARY KEY btree (id)
#  room_messages_idx | btree (room_id, at DESC)
# Foreign key constraints:
#  messages_room_id_fkey | (room_id) REFERENCES rooms(id)
#  messages_user_id_fkey | (user_id) REFERENCES users(id)
