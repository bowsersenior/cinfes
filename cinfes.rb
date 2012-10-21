require 'sinatra/base'
require "sinatra/cookies"
require 'rack-flash'
require 'sinatra/content_for'

require "mongoid"

use Rack::Session::Cookie, :secret => 'add-ob-urt-of-pig-jerd-ap-jidd-up-hy'

Dir["./models/**/*.rb"].each do |file|
  require_relative file
end

Mongoid.load!("db/mongoid.yml")

class Cinfes < Sinatra::Base
  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
  end

  enable :sessions
  use Rack::Flash

  helpers Sinatra::Cookies
  helpers Sinatra::ContentFor

  helpers do
    def find_user(username)
      User.where(:username => username).first
    end

    def current_user
      @current_user ||= find_user(cookies[:current_user])
    end
  end

  get '/' do
    erb :index
  end

  get '/login/:username' do
    u = find_user(params[:username])
    cookies[:current_user] = u.username if u
    redirect '/'
  end

  post '/login' do
    u = find_user(params[:username])
    if u
      cookies[:current_user] = u.username
      flash[:modal] = "Hi #{u.username}!"
      flash[:just_logged_in] = true
    else
      flash[:modal] = "Could not login #{params[:username]}!"
    end

    redirect '/'
  end

  get '/logout' do
    cookies[:current_user] = nil
    redirect '/'
  end

  get '/members/:username' do
    u = find_user(params[:username])
    if u
      erb :member, :locals => {:member => u}
    else
      flash[:notice] = "No member with username: #{params[:username]}!"
      redirect '/'
    end
  end

  get '/movies/1' do
    erb :movie
  end
end