require_relative '../spec_helper'

module FollowerMaze
  describe User do
    before do
     @user = User.new(1, nil)
    end

    it "adds followers" do
      @user.followers.size.should be(0)
      fanboy = User.new(1, nil)
      @user.add_follower(fanboy)
      @user.followers.size.should be(1)
      @user.followers.shift.should be(fanboy)
    end

    it "removes followers" do
      fanboy = User.new(1, nil)
      @user.add_follower(fanboy)
      @user.remove_follower(fanboy)
      @user.followers.empty?.should be_true
    end

    context "with a collection of user" do
      before do
        user_two = User.new(2, nil)
        user_three = User.new(3, nil)
        @users = { @user.id=>@user, user_two.id=>user_two, user_three=>user_three }
      end

      it "creates a new user if they don't exist" do
        new_user = User.create_or_update(4, nil, @users)
        @users.has_value?(new_user).should be_false
      end

      it "updates a user if they already exist" do
        updated_user = User.create_or_update(2, nil, @users)
        @users.has_value?(updated_user).should be_true
      end
    end

  end
end