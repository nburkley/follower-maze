module FollowerMaze

  class User
    attr_reader :id, :connection, :pending_events, :followers

    def initialize(id, connection)
      @id = id
      @connection = connection
      @followers = []
    end

    def add_follower(user)
      @followers << user
    end

    def remove_follower(user)
      @followers.delete(user)
    end

    def connection=(connection)
      @connection = connection
    end

    def self.create_or_update(id, connection, users)
      if users[id]
        users[id].connection=connection
        users[id]
      else
        User.new(id, connection)
      end
    end

  end
end