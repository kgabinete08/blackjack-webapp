require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

BLACKJACK = 21
DEALER_MIN = 17

helpers do
  def calculate_hand(hand)
    arr = hand.map { |card| card[1] }

    total = 0
    arr.each do |value|
      if value == 'Ace'
        total += 11
      else
        total += value.to_i == 0 ? 10 : value.to_i
      end
    end

    arr.select { |value| value == 'Ace' }.count.times do
      break if total <= BLACKJACK
      total -= 10
    end
    total
  end

  def display_card(card)
    suit = card[0].downcase
    value = card[1].downcase
    image = "<img src='/images/cards/#{suit}_#{value}.jpg' class='card'>"
  end
end

before do
  @show_hit_or_stay_buttons = true
  @show_dealer_button = false
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
  if params[:player_name].empty?
    @error = "Please enter a name."
    halt erb :set_name
  end

  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  VALUES = ['Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King']
  SUITS = ['Hearts', 'Diamonds', 'Spades', 'Clubs']
  session[:deck] = SUITS.product(VALUES).shuffle!

  session[:turn] = session[:player_name]

  session[:dealer_hand] = []
  session[:player_hand] = []
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop

  player_total = calculate_hand(session[:player_hand])
  if player_total == BLACKJACK
    redirect '/game/dealer/turn'
  end

  erb :game
end

post '/game/player/hit' do
  session[:player_hand] << session[:deck].pop
  player_total = calculate_hand(session[:player_hand])
  if player_total == BLACKJACK
    @success = "#{session[:player_name]} hit Blackjack!"
    @show_hit_or_stay_buttons = false
    @play_again = true
  elsif player_total > BLACKJACK
    @error = "Sorry #{session[:player_name]} busted!"
    @show_hit_or_stay_buttons = false
    @play_again = true
  end
  erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} chose to stay."
  @show_hit_or_stay_buttons = false
  @show_dealer_button = true
  redirect '/game/dealer/turn'
end

get '/game/dealer/turn' do
  session[:turn] = "Dealer"
  @show_hit_or_stay_buttons = false
  dealer_total = calculate_hand(session[:dealer_hand])
  if dealer_total == BLACKJACK
    @error = "Dealer hit Blackjack!"
    @play_again = true
  elsif dealer_total > BLACKJACK
    @success = "Dealer Busted!"
    @play_again = true
  elsif dealer_total >= DEALER_MIN
    redirect '/game/compare'
  else
    @show_dealer_button = true
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_hand] << session[:deck].pop
  redirect '/game/dealer/turn'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false
  player_total = calculate_hand(session[:player_hand])
  dealer_total = calculate_hand(session[:dealer_hand])

  if player_total < dealer_total
    @error = "Sorry #{session[:player_name]} lost!"
    @play_again = true
  elsif dealer_total < player_total
    @success = "#{session[:player_name]} won!"
    @play_again = true
  else
    @error = "It's a tie!"
    @play_again = true
  end

  erb :game
end

get '/game_over' do

  erb :game_over
end


