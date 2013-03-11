class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_headers

  def set_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Expose-Headers'] = 'ETag'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PATCH, PUT, DELETE, OPTIONS, HEAD'
    headers['Access-Control-Allow-Headers'] = '*,x-requested-with,Content-Type,If-Modified-Since,If-None-Match'
    headers['Access-Control-Max-Age'] = '86400'
  end

  private
  def auth
    authenticate_or_request_with_http_basic do |username, password|
      User.authenticate(username,password)
     end
  end
end
