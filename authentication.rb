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

	if(user && user.login(password))
		session[:user_id] = user.id
		redirect "/dashboard"
	else
		erb :"authentication/invalid_login"
	end
end

get "/logout" do
	session[:user_id] = nil
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


  if name && email && password && phone
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

			erb :"authentication/successful_signup"
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

#if the user is not signed in, will redirect to login page
def authenticate!
	if !current_user
		redirect "/login"
	end
end