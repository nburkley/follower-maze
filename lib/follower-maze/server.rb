module FollowerMaze
  class Server

    def initialize
      @event_socket = TCPServer.new(EVENTS_PORT)
      @user_socket = TCPServer.new(CLIENTS_PORT)
      @event_queue = EventQueue.new()
      @event_feed = nil
    end

    def stop
      Logger.info "Stopping server"
      @user_socket.close if @user_socket
      @event_socket.close if @event_socket
    end

    def start
      Logger.info "Starting server"
      @handles = {}
      @users = {}

      loop do
        to_read = @handles.values.select(&:monitor_for_reading?).map(&:client)
        to_write = @handles.values.select(&:monitor_for_writing?).map(&:client)
        control_sockets = [@event_socket, @user_socket]

        readables, writables = IO.select(to_read + control_sockets, to_write)

        readables.each do |socket|
          if control_sockets.include?(socket)
            Logger.debug("Accepting new conneciton")
            io = socket.accept
            connection = Connection.new(io)
            @handles[io.fileno] = connection
            if socket == @event_socket
              @event_feed = io
            end

          elsif socket == @event_feed
            connection = @handles[socket.fileno]
            event_payload = connection.readline
            if event_payload
              Logger.debug("Read in payload: #{event_payload.chomp}")
              event = Event.new(event_payload)
              @event_queue.add(event)
              @event_queue.send_events(@users)
            else
              Logger.info("Closing event_feed connection")
              @handles.delete(socket.fileno)
              socket.close
              @event_queue.reset
              break
            end

          else
            connection = @handles[socket.fileno]
            data = connection.readline
            if data
              id = data.to_i
              Logger.debug("Read in user id: #{id}")
              user = User.create_or_update(id, connection, @users)
              @users[id] = user
            else
              connection.stop_reading
            end
          end
        end

        writables.each do |socket|
          connection = @handles[socket.fileno]
          connection.on_writable
        end

      end
    end
  end
end