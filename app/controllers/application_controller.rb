class ApplicationController < ActionController::Base
  protect_from_forgery
  
  private
  def auth
    authenticate_or_request_with_http_basic do |username, password|
      User.authenticate(username,password)
     end
  end
end
