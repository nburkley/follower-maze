require_relative '../spec_helper'

module FollowerMaze
  describe Connection do

    context "with the server up and running" do
      before do
        @server = FollowerMaze::Server.new()
        Thread.new do
          @server.start
        end

        @event_client = create_client(EVENTS_PORT)
        @user_clients  = create_client_collection

        @users = @server.send(:users)
        @connection = @users[1].connection
      end

      it "can be set to stop reading" do
        @connection.monitor_for_reading?.should be_true
        @connection.stop_reading
        @connection.monitor_for_reading?.should be_false
      end

      it "returns the correct value for monitor_for_writing" do
        @connection.monitor_for_writing?.should be_false
        @connection.respond("Lorem ipsum"*10_000)
        @connection.monitor_for_writing?.should be_true
      end

      it "reads a line" do
        @user_clients[1].write("3|F|301|1\r\n")
        @connection.readline.should == "3|F|301|1\r\n"
      end

      it "sends responses" do
        @connection.respond("3|F|301|1")
        read_response(@user_clients[1]).should == "3|F|301|1\r\n"
      end

      after { @server.stop }
    end
  end
end