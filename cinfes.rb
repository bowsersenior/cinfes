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

require "yt"

if ! ENV['YOUTUBE_API_KEY'].is_a?(String)
  abort "YOUTUBE_API_KEY env var is missing!"
end

Yt.configure do |config|
  config.api_key = ENV['YOUTUBE_API_KEY']
end

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

    def get_youtube_trailers(title)
      videos = Yt::Collections::Videos.new
      query  = "#{title} trailers"

      # see:
      #   https://developers.google.com/youtube/v3/docs/search/list#parameters
      videos.where({
        q: query,
        maxResults: 25,
        videoCategoryId: 44,  # ID for Trailers
        type: 'video'         # required when 'videoCategoryId' used
      })
    end

    def get_youtube_embed_url(title)
      video_id = get_youtube_trailers(title).first.id

      "http://www.youtube.com/embed/#{video_id}"
    end

    def get_movie_info(q)
      response = HTTParty.get("http://www.omdbapi.com", :query => q)

      info = JSON.parse(response.body)

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

      info['Trailer'] = get_youtube_embed_url(info['Title'])

      flash[:movie_info]    = info
      flash[:movie_poster]  = poster
      flash[:hashtags]      = [ info['Title'].gsub(' ', ''), 'CinFes' ].join(',')
      flash[:movie_hashtag] = info['Title'].gsub(' ', '')
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
    title = if params[:title]
      params[:title].gsub('-', '+')
    else
      nil
    end

    opts = {}

    if title
      opts['t'] = title
    elsif params[:id]
      opts['i'] = params[:id]
    end

    get_movie_info(opts)

    erb :movie
  end

end