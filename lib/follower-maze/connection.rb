module FollowerMaze
  class Connection
    attr_reader :client

    def initialize(io)
      @client = io
      @request, @response = "", ""
      @readable = true
    end

    def stop_reading
      @readable=false
    end

    def monitor_for_reading?
      @readable
    end

    def monitor_for_writing?
      !(@response.empty?)
    end

    def readline
      begin
        Timeout.timeout(DEFAULT_TIMEOUT) do
          @client.gets("\n")
        end
      rescue Timeout::Error
        Logger.error "A timeout occured when reading some input. Connection: #{self.inspect}"
      end
    end

    def respond(message)
      @response << message + CRLF

      # Write what can be written immediately,
      # the rest will be retried next time the
      # socket is writable.
      on_writable
    end

  private
    def on_writable
      bytes = client.write_nonblock(@response)
      @response.slice!(0, bytes)
    end

  end
end