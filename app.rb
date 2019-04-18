require "sinatra"
require 'sinatra/flash'
require_relative "authentication.rb"

#the following urls are included in authentication.rb
# GET /login
# GET /logout
# GET /sign_up

# authenticate! will make sure that the user is signed in, if they are not they will be redirected to the login page
# if the user is signed in, current_user will refer to the signed in user object.
# if they are not signed in, current_user will be nil

def not_found
	halt 404,{message: "User not found"}
end


get "/" do
	erb :index
end


get "/dashboard" do
	authenticate!
	erb :dashboard
end

get "/friends" do
	authenticate!
	erb :friends


end

# Answer from friendship invite
# if Yes will set and current user and sender's invite are_friends to true (meaning are_friends is true for both)
# if No will delete the the friend request from sender and delete it from user's side
# redirects to /requests to continue picking request answers
post "/friends/add_ans" do
	authenticate!
	if params["yes"]
		friendSide = Friends.get(params["yes"])
		friendSide.are_friends = true
		friendSide.save

		num = params["yes"].to_i
		num -= 1
		currentUser = Friends.get(num)
		currentUser.are_friends = true
		currentUser.save


    end

		if params["no"]
			num = params["no"].to_i
			num -= 1

			friendSide = Friends.get(params["no"])
			currentUser = Friends.get(num)


			friendSide.destroy!
			currentUser.destroy!



    end
	redirect "/requests"


end


#if it gets an email will check the database for that user
# if found will make a new Friend and set a temp are_friends to false on requested friend side

post "/friends/add" do
	authenticate!


  if params["email"]

		u = User.first(email: params["email"])
		f = Friends.first(user_id: current_user.id, following_user_id: u.id)

		# You can not be friends with yourself
		if u

			if u.id == current_user.id
				flash[:error] = "You can not be friends with yourself :("
				redirect "/friends"
      else
        # Friend is already in your Friend database
				if f
          flash[:error] = "You are already friends with #{u.email}"
          redirect "/friends"


          #Makes a new Friend sets user id to current and your the user you want to be friends with id
				else
					currentUser_newFriend = Friends.new
					currentUser_newFriend.user_id = current_user.id
					currentUser_newFriend.following_user_id = u.id
					currentUser_newFriend.save

					# Does the same for the person you want to be friends with
          # sets are_friends to false - this is temp
					friendSide = Friends.new
					friendSide.user_id = u.id
					friendSide.following_user_id = current_user.id
					friendSide.are_friends = false
					friendSide.save

          #Sends to page to inform you that the friendship has been sent
          flash[:success] = "Friendship request sent to #{params["email"]}!"
					redirect "/friends"
				end
			end
    else
      # Friend not in the User database
			return not_found

		end
  end

end


#if it gets an email it will check the Friend database
# Will then delete Friend from user's and Friend's side
post "/friends/remove" do
	authenticate!


  if params["email"]
		if params["email"] != current_user.email
			u = User.first(email: params["email"])

			removeFriend = Friends.first(user_id: current_user.id, following_user_id: u.id, are_friends: true)
			removeFreind_CurrentUser = Friends.first(user_id: u.id, following_user_id: current_user.id, are_friends: true)

			if removeFriend and removeFreind_CurrentUser
				removeFriend.destroy!
				removeFreind_CurrentUser.destroy!
        flash[:success] = "Friendship with #{u.email} has been deleted"
				redirect "/friends"
			else
				return not_found
			end
		else
			not_found
		end

  end


end

get "/requests" do
	authenticate!
	erb :requests
end
