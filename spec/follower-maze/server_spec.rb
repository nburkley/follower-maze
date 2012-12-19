require_relative '../spec_helper'

module FollowerMaze
  describe Server do

    before { @server = FollowerMaze::Server.new }

    it "creates a new server" do
      @server.should be_a(FollowerMaze::Server)
    end

    context "with the server runnning," do
      before do
        Thread.new do
          @server.start
        end
      end

      it "accepts connections" do
        expect do
          event_client_socket = create_client(EVENTS_PORT)
          user_client_socket = create_client
          event_client_socket.close
          user_client_socket
        end.to_not raise_error
      end

      context "with client and event sockets set up" do
        before do
          @event_client = create_client(EVENTS_PORT)
          @user_clients = create_client_collection
          wait
        end

        it "forwards a follow notification to a user" do
          sample_payload = "1|F|3|1\r\n"
          @event_client.write(sample_payload)
          read_response(@user_clients[1]).should eql(sample_payload)
          assert_no_client_responses(@user_clients.reject{|k,v| k==1})
        end

        it "forwards no unfollow notifications" do
          sample_payload = "1|U|3|1\r\n"
          @event_client.write(sample_payload)
          assert_no_client_responses(@user_clients)
        end

        it "forwards a brodcast event to all users" do
          sample_payload = "1|B\r\n"
          @event_client.write(sample_payload)
          assert_clients_have_response(@user_clients, sample_payload)
        end

        it "forwards a private message to a user" do
          sample_payload = "1|P|10|1\r\n"
          @event_client.write(sample_payload)
          read_response(@user_clients[1]).should eql(sample_payload)
          assert_no_client_responses(@user_clients.reject{|k,v| k==1})
        end

        it "does not forward a message if a user is not connected" do
          sample_payload = "1|P|10|1\r\n"
          @user_clients[1].close
          @event_client.write(sample_payload)
          assert_no_client_responses(@user_clients.reject{|k,v| k==1})
        end

        it "can handle a user disconnecting and reconnecting" do
          first_payload = "1|P|10|1\r\n"
          @user_clients[1].close
          wait
          @event_client.write(first_payload)
          wait
          reconnecting_client = create_client
          reconnecting_client.write("1\r\n")
          wait

          second_payload = "2|P|10|1\r\n"
          @event_client.write(second_payload)
          read_response(reconnecting_client).should == second_payload
        end

        context "with user 4 and 5 following user 1" do
          before do
            four_follow_one = "1|F|4|1\r\n"
            five_follow_one = "2|F|5|1\r\n"
            @event_client.write(four_follow_one)
            @event_client.write(five_follow_one)
            wait #ensure the follow requests are processed
            read_response(@user_clients[1])
          end

          it "forwards a status update to the followers of a user" do
            sample_payload = "3|S|1\r\n"
            @event_client.write(sample_payload)
            assert_clients_have_response(@user_clients.reject{|k,v| k<4}, sample_payload)
            assert_no_client_responses(@user_clients.reject{|k,v| k>3})
          end

          it "respects an unfollow notification" do
            four_unfollow_one = "3|U|4|1\r\n"
            @event_client.write(four_unfollow_one)
            wait #ensure the follow requests are processed

            status_update_payload = "4|S|1\r\n"
            @event_client.write(status_update_payload)
            read_response(@user_clients[5]).should eql(status_update_payload)
            assert_no_client_responses(@user_clients.reject{|k,v| k==5})
          end

          it "forwards a status update to the followers of a user even if that user is disconnected" do
            @user_clients[1].close
            wait
            sample_payload = "3|S|1\r\n"
            @event_client.write(sample_payload)
            assert_clients_have_response(@user_clients.reject{|k,v| k<4}, sample_payload)
          end

          it "keeps a users followers if they disconnect and reconnect" do
            @user_clients[1].close
            wait
            reconnecting_client = create_client
            reconnecting_client.write("1\r\n")
            wait
            sample_payload = "3|S|1\r\n"
            @event_client.write(sample_payload)
            assert_clients_have_response(@user_clients.reject{|k,v| k<4}, sample_payload)
            read_nonblocking_response(reconnecting_client).should be_nil
          end
        end
      end
      after { @server.stop }
    end
  end
end