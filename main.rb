require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

helpers do
  def calculate_hand(hand)

  end

  def display_card(card)
    
  end
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/set_name'
  end
end

get '/set_name' do
  erb :set_name
end

post '/set_name' do
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  VALUES = ['A', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
  SUITS = ['Hearts', 'Diamonds', 'Spades', 'Clubs']
  session[:deck] = SUITS.product(VALUES).shuffle!

  session[:dealer_hand] = []
  session[:player_hand] = []
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  

  erb :game
end