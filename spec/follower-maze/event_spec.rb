require_relative '../spec_helper'

module FollowerMaze
  describe Event do
    it "parses a follow payload correctly" do
      event = Event.new("576|F|301|231\r\n")
      check_event_values(event, 576, FOLLOW, 301, 231, "576|F|301|231")
    end

    it "parses an unfollow payload correctly" do
      event = Event.new("576|U|301|231\r\n")
      check_event_values(event, 576, UNFOLLOW, 301, 231, "576|U|301|231")
    end

    it "parses a broadcast payload correctly" do
      event = Event.new("576|B\r\n")
      check_event_values(event, 576, BROADCAST, nil, nil, "576|B")
    end

    it "parses a private message payload correctly" do
      event = Event.new("576|P|301|231\r\n")
      check_event_values(event, 576, PRIVATE_MSG, 301, 231, "576|P|301|231")
    end

    it "parses a status update payload correctly" do
      event = Event.new("576|S|301\r\n")
      check_event_values(event, 576, STATUS_UPDATE, 301, nil, "576|S|301")
    end
  end

end