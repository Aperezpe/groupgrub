require File.expand_path '../spec_helper.rb', __FILE__

describe User do
  it { should have_property           :id }
  it { should have_property           :email }
  it { should have_property           :password }
  it { should have_property           :phone }
  it { should have_property           :profile_image_url }
  it { should have_property           :created_at}
end

describe Friends do
  it { should have_property           :id }
  it { should have_property           :user_id}
  it { should have_property           :following_user_id}
end

describe Requests do
  it { should have_property           :id }
  it { should have_property           :user_id }
  it { should have_property           :created_at}
  it { should have_property           :requested_user_id}
  it { should have_property           :event_id}
  it { should have_property           :friend_request_id}
  it { should have_property           :event_request_id}
  it { should have_property           :answer}
  it { should have_property           :clear}
end

describe Group do
  it { should have_property           :id }
  it { should have_property           :user_id }
  it { should have_property           :event_id}
  it { should have_property           :friend_id}
end

describe Event do
  it { should have_property           :id }
  it { should have_property           :user_id }
  it { should have_property           :created_at}
  it { should have_property           :restaurant_id}
  it { should have_property           :event_time}

end


describe Comment do
  it { should have_property           :id }
  it { should have_property           :user_id }
  it { should have_property           :created_at}
  it { should have_property           :comment}
  it { should have_property           :event_id}

end

describe Poll do
  it { should have_property           :id }
  it { should have_property           :user_id }
  it { should have_property           :created_at}
  it { should have_property           :restaurant_id}
  it { should have_property           :event_id}
end

describe Vote do
  it { should have_property           :id }
  it { should have_property           :user_id }
  it { should have_property           :poll_id}
  it { should have_property           :created_at}
end


describe Restaurant do
  it { should have_property           :id }
  it { should have_property           :rest_name }
  it { should have_property           :open_time}
  it { should have_property           :close_time}
  it { should have_property           :rest_phone}
  it { should have_property           :rest_address}

end

describe Dish do
  it { should have_property           :id }
  it { should have_property           :restaurant_id }
  it { should have_property           :dish_name}
  it { should have_property           :dish_des}
  it { should have_property           :dish_price}

end

describe Drink do
  it { should have_property           :id }
  it { should have_property           :restaurant_id }
  it { should have_property           :drink_name}
  it { should have_property           :drink_des}
  it { should have_property           :drink_price}

end

describe Tab do
  it { should have_property           :id }
  it { should have_property           :dish_id }
  it { should have_property           :budget}
  it { should have_property           :cost}
  it { should have_property           :user_id}
  it { should have_property           :isOverBudget}
end
