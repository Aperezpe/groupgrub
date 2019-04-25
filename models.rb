require 'data_mapper' # metagem, requires common plugins too.
require "sinatra"

# need install dm-sqlite-adapter
# if on heroku, use Postgres database
# if not use sqlite3 database I gave you
if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end

class User
    include DataMapper::Resource
    property :id, Serial
    property :name, String
    property :email, String
    property :password, String
    property :phone, Integer
    property :profile_image_url, Text
    property :created_at, DateTime

    def login(password)
        return self.password == password
    end


end


class Friends
  include DataMapper::Resource
  property :id, Serial
  property :user_id, Integer
  property :following_user_id, Integer
  property :are_friends, Boolean
end

class Requests
  include DataMapper::Resource
  property :id, Serial
  property :created_at, DateTime
  property :user_id, Integer
  property :requested_user_id, Integer
  property :event_id, Integer
  property :friend_request_id, Integer
  property :event_request_id, Integer
  property :answer, Boolean
  property :clear, Boolean, :default => true
end

class Group
  include DataMapper::Resource
  property :id, Serial
  property :event_id, Integer
  property :user_id, Integer #Host
  property :friend_id, Integer
  property :is_attending, Boolean
end

class Event
    include DataMapper::Resource
    property :id, Serial
    property :created_at, DateTime
    property :user_id, Integer
    property :restaurant_id, Integer
    property :title, Text
    property :are_events, Boolean
    property :event_date, DateTime

end

class Comment
    include DataMapper::Resource
    property :id, Serial
    property :created_at, DateTime
    property :user_id, Integer
    property :event_id, Integer
    property :comment, Text

end


class Poll
    include DataMapper::Resource
    property :id, Serial
    property :created_at, DateTime
    property :user_id, Integer
    property :event_id, Integer
    property :rest_id, Integer
    property :start, Boolean, :default => false

end

class Vote
    include DataMapper::Resource
    property :id, Serial
    property :user_id, Integer
    property :event_id, Integer
    property :rest_id, Integer
    property :vote, Boolean
    property :created_at, DateTime
end

class Restaurant
    include DataMapper::Resource
    property :id, Serial
    property :rest_name, String
    property :email, String
    property :password, String
    property :open_time, String
    property :close_time, String
    property :rest_phone, Integer
    property :rest_address, String
    property :created_at, DateTime

    def login(password)
      return self.password == password
    end

end

class Dish
    include DataMapper::Resource
    property :id, Serial
    property :restaurant_id, Integer
    property :dish_name, Text
    property :dish_des, Text
    property :dish_price, Integer
end

class Drink
    include DataMapper::Resource
    property :id, Serial
    property :restaurant_id, Integer
    property :drink_name, Text
    property :drink_des, Text
    property :drink_price, Integer
end

class Tab
    include DataMapper::Resource
    property :id, Serial # user submitting to tab
    property :dish_id, Integer # dish or beverage added
    property :budget, Integer # budget set by HOST and only host
    property :cost, Integer # current cost of tab
    property :user_id, Integer
    property :isOverBudget, Boolean, :default => false
    #functions
end




# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the post table
User.auto_upgrade!
Friends.auto_upgrade!
Requests.auto_upgrade!
Group.auto_upgrade!
Event.auto_upgrade!
Comment.auto_upgrade!
Poll.auto_upgrade!
Vote.auto_upgrade!
Restaurant.auto_upgrade!
Dish.auto_upgrade!
Drink.auto_upgrade!
Tab.auto_upgrade!

DataMapper::Model.raise_on_save_failure = true  # globally across all models