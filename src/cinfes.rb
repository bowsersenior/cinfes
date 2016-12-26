require 'sinatra/base'
require "sinatra/cookies"
require 'rack-flash'
require 'sinatra/content_for'
require "open-uri"

use Rack::Session::Cookie, :secret => 'add-ob-urt-of-pig-jerd-ap-jidd-up-hy'

require "yt"

if ! ENV['YOUTUBE_API_KEY'].is_a?(String)
  abort "YOUTUBE_API_KEY env var is missing!"
end

Yt.configure do |config|
  config.api_key = ENV['YOUTUBE_API_KEY']
end

class User
  attr_accessor :username

  def initialize(opts)
    self.username = opts[:username]
  end
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
      u = if username == ENV['CINFES_BOSS_USERNAME']
        username
      else
        "Unknown user"
      end

      User.new(:username => u)
    end

    def current_user
      @current_user ||= find_user(cookies[:current_user])
    end

    def get_youtube_trailers(title)
      # see:
      #   https://developers.google.com/youtube/v3/docs/search/list#parameters
      trailers_category =  Yt::Collections::Videos.new.where({
        q: title,
        maxResults: 25,
        videoCategoryId: 44,  # ID for Trailers
        type: 'video'         # required when 'videoCategoryId' used
      })

      other_category =  Yt::Collections::Videos.new.where({
        q: "#{title} official trailer",
        maxResults: 25
      })

      trailer_vault_videos =  Yt::Collections::Videos.new.where({
        q: title,
        channelId: 'UCTCjFFoX1un-j7ni4B6HJ3Q'
      })

      trailer_vault_videos.map{|v| v} +
        trailers_category.map{|v| v}  +
        other_category.map{|v| v}
    end

    def get_youtube_embed_url(title)
      trailer = get_youtube_trailers(title).find do |video|
        video.title =~ /^#{title.downcase}/i &&
          (
            video.title.downcase.include?('trailer') ||
            video.title.downcase.include?('preview')
          )
      end

      if trailer
        "http://www.youtube.com/embed/#{trailer.id}"
      else

        nil
      end
    end

    def get_movie_info(q)
      response = HTTParty.get("http://www.omdbapi.com", :query => q)

      info = JSON.parse(response.body)

      poster_url = info.delete('Poster')

      if ! poster_url
        return nil
      end

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

    if get_movie_info(opts)
      erb :movie
    else
      status 404
      "Couldn't find data for params: #{params}"
    end
  end

end