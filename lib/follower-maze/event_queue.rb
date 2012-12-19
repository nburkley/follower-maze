module FollowerMaze
  class EventQueue

    attr_reader :events

    def initialize
      @events = []
      @next_seq_id_to_send = 1
    end

    def add(event)
      @events << event
      @events.sort_by!(&:seq_id)
    end

    def empty?
      @events.empty?
    end

    def send_events(users)
      for event in events_to_send
        process_event(event, users)
      end
    end

    def reset
      @next_seq_id_to_send = 1
    end

  private

    def events_to_send
      events=[]
      while @events.first && (@events.first.seq_id == @next_seq_id_to_send)
        events << @events.shift
        @next_seq_id_to_send += 1
      end
      events
    end

    def process_event(event, users)
      case event.type
      when FOLLOW
        if users[event.to_user_id]
          Logger.debug("Send #{event.payload} to user#{event.to_user_id}")
          users[event.to_user_id].add_follower(users[event.from_user_id])
          users[event.to_user_id].connection.respond(event.payload)
        end
      when UNFOLLOW
        Logger.debug("No notifications for #{event.payload}")
        if users[event.to_user_id]
          users[event.to_user_id].remove_follower(users[event.from_user_id])
        end
      when BROADCAST
        Logger.debug("Send #{event.payload} to all users")
        users.values.each do |user|
          user.connection.respond(event.payload)
        end
      when PRIVATE_MSG
        if users[event.to_user_id]
          Logger.debug("Send #{event.payload} to user#{event.to_user_id}")
          users[event.to_user_id].connection.respond(event.payload)
        end
      when STATUS_UPDATE
        if users[event.from_user_id]
          Logger.debug "send #{event.payload} to followers of user#{event.from_user_id}"
          users[event.from_user_id].followers.each do |follower|
            follower.connection.respond(event.payload)
          end
        end
      else
        #ignore anything else
      end
    end
  end
end