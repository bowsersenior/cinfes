require 'sinatra/base'
require "sinatra/cookies"
require 'rack-flash'
require 'sinatra/content_for'
require "open-uri"

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

  MOVIES = {
    'tt0097576' => 'The Big Lebowski',

  }

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

    def get_movie_info(q)
      s = HTTParty.get("http://www.omdbapi.com", :query => q)

      info = JSON.parse(s)

      poster_url = info.delete('Poster')
      local_image = "./public/images/#{info['imdbID']}.jpg"

      if !File.exists?(local_image)
        open(poster_url) do |f|
          File.open(local_image,"wb") do |file|
            file.puts f.read
          end
        end
      end

      poster = local_image.gsub('./public', '')

      info.delete('Response')

      flash[:movie_info]   = info
      flash[:movie_poster] = poster
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
      flash[:notice] = "Hi #{u.username}!"
      flash[:just_logged_in] = true
    else
      flash[:error] = "Could not login #{params[:username]}!"
    end

    redirect '/'
  end

  get '/logout' do
    flash[:notice] = "Buh-bye #{current_user.username}!"
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

  get '/movies' do
    title = (params[:title] || '').gsub('-', '+')
    opts = {:t => title, :i => params[:id]}
    get_movie_info(opts)

    erb :movie
  end

end