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
	# @req = Requests.all(requested_user_id: current_user.id)
	erb :requests
end


#Create

post "/events/new" do
	authenticate!

	e = Event.new
	e.user_id = current_user.id
	e.restaurant_id = nil
	e.title = params["title"]
	e.event_date = params["d_date"]

	if e.save
		g = Group.new
		g.event_id = e.id
		g.user_id = current_user.id
		g.friend_id = -1
		g.save
		flash[:success] = "Dinner has been created successfully"
		redirect "/events"
	else
		flash[:error] = "There was an error creating the event, please try again"
		redirect "/events"
	end


end

post "/events/:id/newFriend" do
	authenticate!
	e_id = params[:id]
	dinner = Event.first(id: e_id)
	u = User.first(email: params["email"])
	#f = Friends.first(user_id: current_user.id, following_user_id: u.id, are_attending: true)


	if params["email"] && u
		# @email = params["email"]
		# erb :event
		req = Requests.first(user_id: current_user.id, requested_user_id: u.id, event_id: e_id)

		if u.id == current_user.id
			flash[:error] = "You can't invite your self"
			redirect "/events/#{e_id}"
		else
			if req
				flash[:error] = "You already ivited #{u.email}"
				redirect "/events/#{e_id}"
			else
				#Send request
				f = Friends.first(user_id: current_user.id, following_user_id: u.id)

				if f
					new_Req = Requests.new
					new_Req.user_id = current_user.id 
					new_Req.requested_user_id = u.id
					new_Req.event_id = e_id
					new_Req.save

					flash[:success] = "Your friend has been invited"
					redirect "/events/#{e_id}"
				else
					flash[:error] = "You can't invite someone that is not your friend"
					redirect "/events/#{e_id}"
				end

				
			end
		end
	else
		flash[:error] = "This user does not exist"
		redirect "/events/#{e_id}"
	end

end

post "/events/:id/response" do
	authenticate!
	req = Requests.first(event_id: params[:id], requested_user_id: current_user.id)
	e = Event.first(id: params[:id])

	## If such request exist
	if req 
		if params["radio-choice"] == "yes"

			g = Group.new
			g.event_id = req.event_id
			g.user_id = req.user_id #Host of group
			g.friend_id = req.requested_user_id

			if g.save
				flash[:success] = "Welcome to #{e.title}"
				req.destroy
				redirect "/events/#{params[:id]}"
			else
				flash[:error] = "There was an error"
				redirect "/dashboard"
			end
		else
			req.destroy
			flash[:error] = "You have rejected the event"
			redirect "/dashboard"
		end

		

		

		
		
	end

end

#Read

get "/events" do
	authenticate!
	@req = Requests.all(requested_user_id: current_user.id)
	@my_dinners = Event.all(user_id: current_user.id)
	@dinners = Group.all(friend_id: current_user.id)
	erb :events
end

get "/events/:id" do
	authenticate!
	#Have to check if the current_user is attending. If not, he can't see event content
	
	@dinner = Event.first(id: params[:id])

	#If the host wants to access to the event, go to event
	if current_user.id == @dinner.user_id
		erb :event
	else
		g = Group.first(event_id: params[:id], friend_id: current_user.id)
		if g
			erb :event
		else
			flash[:error] = "You can't access to this event"
			redirect "/dashboard"
		end
	end
	
end

#Update

#Destroy

post "/events/delete" do
	authenticate!

	e = Event.get(params["id"])
	g = Group.all(event_id: e.id)

  if e
		e.destroy
		g.destroy
		flash[:success] = "Dinner has been deleted!"
		redirect "/events"

	else
		flash[:error] = "Dinner not found"
		redirect "/events"

	end


end

post "/events/:id/deleteFriend" do
	authenticate!

	g = Group.all(friend_id: params["friendID"])
	u = User.first(id: params["friendID"])

	if g
		g.destroy
		flash[:success] = "#{u.email} has been uninvited"
		redirect "/events/#{params[:id]}"
	else
		flash[:error] = "Friend not found"
		redirect "/events/#{params[:id]}"
	end

end

# delete request

post "/requests/:id/delete" do
	req = Requests.first(id: params[:id])

	if req.destroy
		return "The request has been deleted"
	end

end
