require 'sinatra/base'
require "sinatra/cookies"

require "mongoid"

use Rack::Session::Cookie, :secret => 'add-ob-urt-of-pig-jerd-ap-jidd-up-hy'

Dir["./app/**/*.rb"].each do |file|
  require_relative file
end

Mongoid.load!("db/mongoid.yml")

class Cinfes < Sinatra::Base
  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
  end

  helpers Sinatra::Cookies

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
    cookies[:current_user] = u.username if u
    redirect '/'
  end

  get '/logout' do
    cookies[:current_user] = nil
    redirect '/'
  end
end