module FollowerMaze
  class Event

    attr_reader :seq_id, :type, :from_user_id, :to_user_id, :payload

    def initialize(payload)
      @payload = payload.chomp
      event_parts = payload.chomp.split("|")
      @seq_id = event_parts[SEQUENCE_ID].to_i
      @type = event_parts[EVENT_TYPE]
      @from_user_id = event_parts[FROM_USER_ID].to_i if event_parts[FROM_USER_ID]
      @to_user_id = event_parts[TO_USER_ID].to_i if event_parts[TO_USER_ID]
    end

  end
end