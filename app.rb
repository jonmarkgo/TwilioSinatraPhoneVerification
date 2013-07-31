require "sinatra"
require "sinatra/multi_route"
require "data_mapper"
require "twilio-ruby"
require "sanitize"
require "erb"
include ERB::Util

DataMapper::Logger.new(STDOUT, :debug)
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/dev.db")

class VerifiedUser
  include DataMapper::Resource

  property :id, Serial
  property :code, String, :length => 10
  property :phone_number, String, :length => 30
  property :verified, Boolean, :default => false

end
DataMapper.finalize
DataMapper.auto_upgrade!

before do
  @twilio_number = ENV['twilio_number']
  @client = Twilio::REST::Client.new ENV['account_sid'], ENV['auth_token']

  if params[:error].nil?
    @error = false
  else
    @error = true
  end

end

get "/" do
  erb :index
end

route :get, :post, '/register' do
  @phone_number = Sanitize.clean(params[:phone_number])
  if @phone_number.empty?
    redirect to("/?error=1")
  end

  begin
    if @error == false
      user = VerifiedUser.first_or_create(:phone_number => @phone_number)

      if user.verified == true
        @phone_number = url_encode(@phone_number)
        redirect to("/verify?phone_number=#{@phone_number}&verified=1")
      end
      totp = ROTP::TOTP.new("drawtheowl")
      code = totp.now
      user.code = code
      user.save

      @client.account.sms.messages.create(
        :from => @twilio_number,
        :to => @phone_number,
        :body => "Your verification code is #{code}")
    end
    erb :register
  rescue
    redirect to("/?error=2")
  end
end

route :get, :post, '/verify' do

  @phone_number = Sanitize.clean(params[:phone_number])

  @code = Sanitize.clean(params[:code])
  user = VerifiedUser.first(:phone_number => @phone_number)
  if user.verified == true
    @verified = true
  elsif user.nil? or user.code != @code
    @phone_number = url_encode(@phone_number)
    redirect to("/register?phone_number=#{@phone_number}&error=1")
  else
    user.verified = true
    user.save
  end
  erb :verified
end