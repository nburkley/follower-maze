require 'rspec'
require_relative '../lib/follower-maze'

EVENTS_PORT = 9090
CLIENTS_PORT = 9099
CHUNK_SIZE = 1024 * 16
CRLF = "\r\n"
FOLLOW = "F"
UNFOLLOW = "U"
BROADCAST = "B"
PRIVATE_MSG = "P"
STATUS_UPDATE = "S"
SEQUENCE_ID = 0
EVENT_TYPE = 1
FROM_USER_ID = 2
TO_USER_ID = 3


DEFAULT_WAIT_TIME = 1
DEFAULT_TIMEOUT = 5

def create_client(port=CLIENTS_PORT)
  begin
    TCPSocket.new('localhost', port)
  rescue
    retry
  end
end

def read_response(user_client)
  begin
    Timeout.timeout(DEFAULT_TIMEOUT) do
      user_client.readpartial(CHUNK_SIZE)
    end
  rescue Timeout::Error
    puts "TIMEOUT ERROR - you may want to increase the 'DEFAULT_WAIT_TIME' in #{__FILE__}"
  end
end

def create_client_collection(count=5)
  user_clients  = {}
  1.upto(5) do |i|
    client = create_client
    client.write("#{i}\n")
    user_clients[i] = client
  end
  wait(2) #ensure clients are connected before we start
  user_clients
end

def read_nonblocking_response(user_client)
  begin
    user_client.read_nonblock(CHUNK_SIZE)
  rescue Errno::EAGAIN
    nil
  rescue EOFError
    nil
  end
end

def wait(seconds = DEFAULT_WAIT_TIME)
  sleep(seconds)
end

def check_event_values(event, seq_id, type, from_user_id, to_user_id, payload)
  event.seq_id.should be(seq_id)
  event.type.should == type
  event.from_user_id.should be(from_user_id)
  event.to_user_id.should be(to_user_id)
  event.payload.should == payload
end

def assert_no_client_responses(user_clients)
  user_clients.values.each do |user_client|
    read_nonblocking_response(user_client).should be_nil
  end
end

def assert_clients_have_response(user_clients, response)
  user_clients.values.each do |user_client|
    read_response(user_client).should == response
  end
end


module FollowerMaze
  class Server
  private
    def users #allow tests access to the servers users collection
      @users
    end
  end
end