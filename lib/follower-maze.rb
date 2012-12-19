require 'pry'
require 'socket'
require 'logger'
require 'timeout'

require_relative 'follower-maze/connection'
require_relative 'follower-maze/user'
require_relative 'follower-maze/event'
require_relative 'follower-maze/event_queue'
require_relative 'follower-maze/server'

module FollowerMaze
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
  DEFAULT_TIMEOUT = 5
end

module FollowerMaze
  log_file = File.dirname(__FILE__) + '/../log/follower-maze.log'
  logger = Logger.new( log_file, 'daily' )
  logger.level = Logger::DEBUG
  Logger = logger
end