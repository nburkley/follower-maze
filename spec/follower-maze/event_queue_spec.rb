require_relative '../spec_helper'

module FollowerMaze
  describe EventQueue do

    before do
      @event_queue = EventQueue.new
    end

    it "knows if it's empty" do
      @event_queue.empty?.should be_true
      @event_queue.add(Event.new("576|F|301|231\r\n"))
      @event_queue.empty?.should be_false
    end

    it "adds events" do
      @event_queue.empty?.should be_true
      @event_queue.add(Event.new("576|F|301|231\r\n"))
      @event_queue.events.size.should be(1)
    end

    context "with some events," do
      before do
        @event_queue.add(Event.new("175|U|301|231\r\n"))
        @event_queue.add(Event.new("3|F|301|1\r\n"))
        @event_queue.add(Event.new("1|F|301|2\r\n"))
        @event_queue.add(Event.new("2|P|301|3\r\n"))
      end

      it "keeps events in order" do
        @event_queue.add(Event.new("100|U|301|231\r\n"))
        @event_queue.events.first.seq_id.should be(1)
        @event_queue.events[1].seq_id.should be(2)
        @event_queue.events.last.seq_id.should be(175)
      end

      it "knows what events it can send now" do
        @event_queue.send(:events_to_send).map(&:seq_id).should == [1,2,3]
      end

      context "with a server running and clients setup" do
        before do
          @server = FollowerMaze::Server.new()
          Thread.new do
            @server.start
          end

          #create connections
          @event_client = create_client(EVENTS_PORT)
          @user_clients  = create_client_collection

          #get the user collection from the server
          @users = @server.send(:users)
        end

        it "sends the correct events" do
          @event_queue.send_events(@users)
          read_response(@user_clients[1]).should == "3|F|301|1\r\n"
          read_response(@user_clients[2]).should == "1|F|301|2\r\n"
          read_response(@user_clients[3]).should == "2|P|301|3\r\n"
        end

        it "processes a follow event correctly" do
          @users[1].followers.empty?.should be_true
          event = Event.new("1|F|5|1\r\n")
          @event_queue.send(:process_event, event, @users)
          read_response(@user_clients[1]).should == "1|F|5|1\r\n"
          @users[1].followers.first.should be(@users[5])
          assert_no_client_responses(@user_clients.reject{|k,v| k==1})
        end

        it "processes an unfollow event correctly" do
          @users[1].add_follower(@users[5])
          event = Event.new("1|U|5|1\r\n")
          @event_queue.send(:process_event, event, @users)
          assert_no_client_responses(@user_clients)
          @users[1].followers.empty?.should be_true
        end

        it "processes a broadcast event correctly" do
          event = Event.new("1|B\r\n")
          @event_queue.send(:process_event, event, @users)
          assert_clients_have_response(@user_clients, "1|B\r\n")
        end

        it "process a private message correctly" do
          event = Event.new("1|P|5|1\r\n")
          @event_queue.send(:process_event, event, @users)
          read_response(@user_clients[1]).should == "1|P|5|1\r\n"
          assert_no_client_responses(@user_clients.reject{|k,v| k==1})
        end

        it "processes a status update correctly" do
          @users[1].add_follower(@users[5])
          @users[1].add_follower(@users[4])
          event = Event.new("1|S|1\r\n")
          @event_queue.send(:process_event, event, @users)
          assert_clients_have_response(@user_clients.reject{|k,v| k<4}, "1|S|1\r\n")
          assert_no_client_responses(@user_clients.reject{|k,v| k>3})
        end

        it "does nothing for an unfollow event if the follower is not found" do
          @users[1].followers.empty?.should be_true

          non_follower_event = Event.new("1|U|5|1\r\n")
          @event_queue.send(:process_event, non_follower_event, @users)
          assert_no_client_responses(@user_clients)

          non_user_event = Event.new("1|U|500|1\r\n")
          @event_queue.send(:process_event, non_follower_event, @users)
          assert_no_client_responses(@user_clients)
        end

        it "does nothing for a follow event if the follower is not found" do
          @users[1].followers.empty?.should be_true
          event = Event.new("1|F|500|1\r\n")
          assert_no_client_responses(@user_clients)
        end

        after { @server.stop }
      end
    end
  end
end
