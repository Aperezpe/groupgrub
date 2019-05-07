require "sinatra"
require 'sinatra/flash'
require_relative "views/authentication.rb"

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
	authenticate!
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

          g = Group.all(user_id: current_user.id, friend_id: u.id)

          if g
            g.each do |d|
              g.destroy!
            end
          end

          e =Event.all(user_id: current_user.id)
          if e
            e.each do |e|
              v = Vote.all(event_id: e.id, user_id: u.id)
              if v
                v.each do |x|
                  x.destroy!
                end
              end

            end
          end

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


  if params["title"] and params["d_date"] and params["d_time"]

	e = Event.new
	e.user_id = current_user.id
	e.restaurant_id = nil
	e.title = params["title"]
	e.event_date = params["d_date"]+ "T" + params["d_time"]

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
  else
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
				flash[:error] = "You already invited #{u.email}"
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


  if params[:name]
    event= Event.first(user_id: current_user.id, title: params[:name])
    if event

      g = Group.all(user_id: current_user.id, event_id: event.id)
      g.destroy! if g

      p = Poll.all(user_id: current_user.id,event_id: event.id)
      p.destroy! if p

      v = Vote.all(event_id: event.id)
      v.destroy! if v

      c = Comment.all(event_id: event.id)
      c.destroy! if c

      t = Tab.all(event_id: event.id)
      t.destroy! if t

      event.destroy!

			flash[:success] = "Dinner has been deleted!"
			redirect "/events"

		else
			flash[:error] = "Dinner not found"
			redirect "/events"

		end
	else
		flash[:error] = "Not found"
		redirect "/events"
  end

end

post "/events/:id/delete" do

  if params[:id]

		event= Event.first(user_id: current_user.id, id: params[:id])

    if event
			if event

				g = Group.all(user_id: current_user.id, event_id: event.id)
				g.destroy! if g

				p = Poll.all(user_id: current_user.id,event_id: event.id)
				p.destroy! if p

				v = Vote.all(event_id: event.id)
				v.destroy! if v

				c = Comment.all(event_id: event.id)
				c.destroy! if c

				t = Tab.all(event_id: event.id)
				t.destroy! if t

				event.destroy!

				flash[:success] = "Dinner has been deleted!"
				redirect "/events"

			else
				flash[:error] = "Dinner not found"
				redirect "/events"

			end
    end

  else
		flash[:error] = "Not found"
		redirect "/events"

  end


end



post "/events/:id/deleteFriend" do
	authenticate!

  if params[:id]
		u = User.first(email: params["email"])

    if u
      g =Group.first(event_id: params[:id], friend_id: u.id)
      if g
        g.destroy!
				flash[:success] = "#{u.email} has been uninvited"
				redirect "/events/#{params[:id]}"
      else
				flash[:error] = "#{u.email} is not in your event"
				redirect "/events/#{params[:id]}"

      end
    end
  else
		flash[:error] = "Error"
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
    flash[:success] = "You left #{name_event.title} invite"
    redirect "/events"
  end

end


# Host can add res to an their event
post "/events/:id/addRes"do
	authenticate!

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


post "/events/:id/create_Poll" do
	authenticate!

  if params[:id] and params["rest_name"]

		rest = Restaurant.first(rest_name: params["rest_name"])

    if rest
			poll = Poll.first(event_id: params[:id], rest_id: rest.id)
      if poll
				flash[:error] = "#{params["rest_name"]} is already a candidate"
				redirect "/events/#{params[:id]}"
      else
				if (Poll.all(event_id: params[:id]).count + 1) != (Group.all(event_id: params[:id]).count)
					poll = Poll.new
					poll.user_id = current_user.id
					poll.event_id = params[:id]
					poll.rest_id = rest.id
					poll.save
					flash[:success] = "#{params["rest_name"]} was added as a candidate"
					redirect "/events/#{params[:id]}"
				else
					flash[:error] = "Polling is above limit "
					redirect "/events/#{params[:id]}"

				end
      end


    else
			flash[:error] = "Restaurant not found"
			redirect "/events/#{params[:id]}"

	end
  else
    flash[:error] = "Event not found"
		redirect "/events"

  end
end




# To start the poll - just sets it to true
post "/events/:id/startPoll"do
  authenticate!

  if params[:id]

    rest = Poll.first(event_id: params[:id])

    if rest.user_id == current_user.id

      Poll.all(user_id: current_user.id, event_id: params[:id]).each do |p|
        p.start = true
        p.save
      end
			flash[:success] = "Polling has started"
			redirect "/events/#{params[:id]}"
    else
      flash[:error] = "Error"
			redirect "/events/#{params[:id]}"
    end


  else
    redirect '/'
  end

end


# Placing vote
post "/events/:id/vote" do
  authenticate!

  if params[:id] and params[:vote]

    v = Vote.first(user_id: current_user.id, event_id: params[:id])
    if v
      flash[:error] = "You have already voted"

    else
      v = Vote.new
      v.user_id = current_user.id
      v.event_id = params[:id]
      v.rest_id = params[:vote]
      v.vote = true
      v.save

      flash[:success] = "Vote placed"

    end
		redirect "/events/#{params[:id]}"

  else
    redirect "/"
  end
end



# On rest side see menu and option to add new items
get "/emenu" do
  res_authenticate!
  erb :emenu
end

# rest side add new items to menu
post "/emenu/:id/addItem" do
  res_authenticate!

  if params[:id]
    d= Dish.first(restaurant_id: params[:id], dish_name: params[:name])
    if d
      flash[:error] = "#{params[:name]} is already in your menu"
      redirect "/emenu"
    else
      dish = Dish.new
      dish.restaurant_id = params[:id]
      dish.dish_name = params[:name]
      dish.dish_des = params[:des]
      dish.dish_price = params[:price]
      dish.save
      flash[:success] = "#{params[:name]} was added to your menu"
      redirect "/emenu"
    end

  end


end



# rest side delete item
post "/emenu/:id/delete" do
	res_authenticate!

	if params[:id]
		d= Dish.first(restaurant_id: params[:id], dish_name: params[:name])
		if d
      d.destroy!
			flash[:success] = "#{params[:name]} was deleted from your menu"
			redirect "/emenu"


		else
			flash[:error] = "#{params[:name]} was not found in your menu"
			redirect "/emenu"
		end

	end

end


#User select item from rest's menu
get "/events/:id/menu/:res" do
  authenticate!

	@dinner = Event.first(id: params[:id])
  @res = Restaurant.first(id: params[:res])
  erb :selectDish

end


#User selection is saved
post "/events/:id/addItem/:res" do
  authenticate!


  if params[:id] and params[:res]

    order = Tab.first(event_id: params[:id], user_id: current_user.id)

    if order
      flash[:error] = "You have already placed your order"
      redirect "/events/#{params[:id]}"
    else
      t = Tab.new
      t.event_id = params[:id]
      t.user_id = current_user.id
      t.dish_id = params[:dishID]
      t.save
      flash[:success] = "Your order has been placed"
      redirect "/events/#{params[:id]}"

    end
  end
end



#User deletes their order
post "/events/:id/deleteOrder/:res" do
	authenticate!


	if params[:id] and params[:res]

		order = Tab.first(event_id: params[:id], user_id: current_user.id, dish_id: params[:res])

		if order
      order.destroy!
			flash[:success] = "Your order was deleted"
			redirect "/events/#{params[:id]}"
		else
			flash[:error] = "Your order was not found"
			redirect "/events/#{params[:id]}"

		end
	end
end


#View Order
get "/events/:id/order/:res" do
	authenticate!
	@dinner = Event.first(id: params[:id])
	@res = Restaurant.first(id: params[:res])
  erb :order
end


#View total cost
get "/events/:id/total/:res" do
	authenticate!
	@dinner = Event.first(id: params[:id])
  erb :total

end



########COMMENTS#######

#CREATE
post "/comment/:id/new" do
	authenticate!

	dinner = Event.get(params[:id])

	#If dinner exists and a comment is fount in parameters, create new comment
	if dinner and params["comment"]
		new_com = Comment.new
		new_com.comment = params["comment"]
		new_com.user_id = current_user.id
		new_com.event_id = params[:id]
		if new_com.save
			flash[:success] = "Comment posted!"
			redirect "/events/#{params[:id]}"
		else
			flash[:error] = "There was an error posting your comment, please try again!"
			redirect "/events/#{params[:id]}"
		end
	else
		flash[:error] = "Dinner or comment not found!"
		redirect "/events/#{params[:id]}"

	end
end
#READ
#UPDATE
#DESTROY

post "/comment/:id/destroy" do

	com = Comment.first(id: params[:id])
	e_id = Event.first(id: com.event_id)

	puts "current user ID: #{current_user.id}"
	puts "user that put the comment ID: #{current_user.id}"
	puts com.comment

	if current_user.id.to_i == com.user_id.to_i
		com.destroy
		flash[:success] = "Comment deleted!"
		redirect "/events/#{e_id.id}"
	else
		flash[:error] = "You can't delete someone else's comment!"
		redirect "/events/#{e_id.id}"
	end

end

get "/events/rest/:r_id" do 

	if params[:r_id]
	 erb :menu
	
		
	
	
	else
		redirect "/events"

	
		
	end

end

