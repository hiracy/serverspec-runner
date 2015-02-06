RSpec::Matchers.define :be_replicated do
  match do |host|
    host.replicated?(@master, @user, @password, @port)
  end

  chain :from do |master|
    @master = master
  end

  chain :with_user do |user|
    @user = user
  end
  
  chain :with_password  do |password|
    @password = password
  end
  
  chain :with_port do |port|
    @port = port
  end
end
