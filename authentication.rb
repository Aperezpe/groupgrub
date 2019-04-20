require 'sinatra'
require_relative "models.rb"

enable :sessions

set :session_secret, 'super secret'

get "/login" do
	erb :"authentication/login"
end


post "/process_login" do
  email = params[:email]
  password = params[:password]

	user = User.first(email: email.downcase)
	res = Restaurant.first(email: email.downcase)

  if user
		if user.login(password)
			session[:user_id] = user.id
			redirect "/dashboard"
    end
  end

  if res
		if res.login(password)
			session[:res_id] = res.id
			redirect "/res"
		end

  end

	erb :"authentication/invalid_login"




end

get "/logout" do
	session[:user_id] = nil if session[:user_id]
	session[:res_id] = nil if session[:res_id]
	redirect "/"
end

get "/sign_up" do
	erb :"authentication/sign_up"
end


post "/register" do
	name = params[:name]
	email = params[:email]
	password = params[:password]
	phone = params[:phone]
  checkbox = params[:checkbox]

	if name && email && password && phone && checkbox
    if checkbox == "individual"

			check = User.first(email: email.downcase)

			if check
				halt 422, {"message": "Email already in use"}.to_json
			else
				u = User.new
				u.name = name
				u.email = email.downcase
				u.password =  password
				u.phone = phone
				u.save

				session[:user_id] = u.id
				redirect "/dashboard"
      end
    end

    if checkbox == "restaurant"
			check = Restaurant.first(email: email.downcase)

			if check
				halt 422, {"message": "Email already in use"}.to_json

			else
				r = Restaurant.new
				r.rest_name = name
				r.email = email.downcase
				r.password =  password
				r.rest_phone = phone
				r.save
				session[:res_id] = r.id

        redirect "/res"

      end
    end

  end





end

#This method will return the user object of the currently signed in user
#Returns nil if not signed in
def current_user
	if(session[:user_id])
		@u ||= User.first(id: session[:user_id])
		return @u
	else
		return nil
	end
end

def current_res_user
	if(session[:res_id])
		@r ||= Restaurant.first(id: session[:res_id])
		return @r
	else
		return nil
	end
end


#if the user is not signed in, will redirect to login page
def authenticate!
	if !current_user
		redirect "/login"
	end
end

def res_authenticate!
	if !current_res_user
		redirect "/login"
	end
end