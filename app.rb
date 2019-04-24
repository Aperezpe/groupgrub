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

# Restaurant Dashboard
get "/res" do
	res_authenticate!
	erb :res_dashboard
end


# User Dashboard
get "/dashboard" do

	erb :dashboard
end

# User account info
get "/account" do
	authenticate!
	erb :account
end

# Edit User account
get "/account/edit" do
	authenticate!
  erb :account_edit
end

# Save changes to User account
post "/account/update" do
	authenticate!

  user = User.first(id: current_user.id)

  if user
    user.name = params["name"] if params["name"]
		user.email = params["email"] if params["email"]
		user.phone = params["phone"] if params["phone"]

		user.save
		flash[:success] ="Account successfully updated!"
		redirect "/account"

  else
    flash[:error] ="Not authorized"
    redirect "/"
  end
end

# Restaurant account info
get "/res_account" do
	res_authenticate!
	erb :res_account
end


# Edit Restaurant account info
get "/res_account/edit" do
	res_authenticate!
	erb :res_account_edit
end

# Save changes to Restaurant account info
post "/res_account/update" do
	res_authenticate!

	res = Restaurant.first(id: current_res_user.id)

  if res

		res.email = params["email"] if params["email"]
		res.password = params["password"] if params["password"]
		res.open_time = params["open"] if params["open"]
		res.close_time = params["close"] if params["close"]
    res.rest_phone = params["phone"] if params["phone"]
		res.rest_address = params["address"] if params["address"]


		res.save

		flash[:success] = "Account successfully updated!"
		redirect "/res_account"

	else
		flash[:error] ="Not authorized"
		redirect "/"

  end
end


# All Users' friends
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


	if params["answer"]

		num = params["answer"].to_i

    # Positive number means Accept from request
    if num > 0
      friendSide = Friends.get(params["answer"])
      if friendSide
        friendSide.are_friends = true
        friendSide.save

        num -= 1
        currentUser = Friends.get(num)
        currentUser.are_friends = true
        currentUser.save
      else
				flash[:error] = "Request does not exist"
      end

      # Negative number means Deny from request
    else

      num = num * -1
      friendSide = Friends.get(num)
			if friendSide

				friendSide.destroy!

				num -= 1
				currentUser = Friends.get(num)
				currentUser.destroy!
      else
				flash[:error] = " Neg Request does not exist"

      end

    end

  else
		flash[:error] = "Request does not exist"

  end

	redirect "/requests"
end


#if it gets an email will check the database for that user
# if found will make a new Friend and set a temp are_friends to false on requested friend side

post "/friends/add" do
	authenticate!


  if params["email"]

		u = User.first(email: params["email"])


		# You can not be friends with yourself
		if u
			f = Friends.first(user_id: current_user.id, following_user_id: u.id)
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
			flash[:error] ="#{params["email"]} not found"
      redirect "/friends"

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
      if u

				removeFriend = Friends.first(user_id: current_user.id, following_user_id: u.id, are_friends: true)
				removeFreind_CurrentUser = Friends.first(user_id: u.id, following_user_id: current_user.id, are_friends: true)

				if removeFriend and removeFreind_CurrentUser
					removeFriend.destroy!
					removeFreind_CurrentUser.destroy!
        	flash[:success] = "Friendship with #{u.email} has been deleted"
					redirect "/friends"
				else
					flash[:error] = "#{params["email"]} was not found in your friends' list"
					redirect "/friends"
				end
			else
			flash[:error] = "#{params["email"]} was not found in your friends' list"
			redirect "/friends"
			end
    end
  end
end


# All requests
get "/requests" do
	authenticate!
	#@req = Requests.all(requested_user_id: current_user.id)
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
      g.save

			if g.save
				flash[:success] = "Welcome to #{e.title}"
				req.destroy
				redirect "/requests"
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
  #@friends = Friends.all(user_id: current_user.id, are_friends: true)
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
	authenticate!
	req = Requests.first(id: params[:id])

	if req.destroy
		return "The request has been deleted"
	end

end

# Cancel request

post "/events/:id/cancel" do
	authenticate!

  event = Group.first(event_id: params[:id], friend_id: current_user.id)
  name_event = Event.first(id: params[:id])

  if event and name_event
    event.destroy
    flash[:success] = "#{name_event.title} was canceled"
    redirect "/events"
  end

end


post "/events/:id/addRes"do

  if params[:id] and params[:rest_name]
  rest_id = Restaurant.first(rest_name: params[:rest_name])
    if rest_id
      event = Event.first(id: params[:id])
      if event and event.user_id == current_user.id
        event.restaurant_id = rest_id.id
        event.save
        flash[:success] = "#{params[:rest_name]} added to #{event.title}"
				redirect "/events/#{event.id}"

      end

  else
    flash[:error] = "#{params[:rest_name]} not found"
    redirect "/events/#{params[:id]}"

    end
	end

end
