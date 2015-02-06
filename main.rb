require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK = 21
DEALER_MIN = 17

helpers do

  def initialize_deck
    values = ['Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King']
    suits = ['Hearts', 'Diamonds', 'Spades', 'Clubs']

    deck = []
    values.each do |value|
      suits.each do |suit|
        deck << [value, suit]
      end 
    end
    deck.shuffle!
  end

  def calculate_hand(hand)
    total = 0

    hand.each do |card|
      if card[0] == 'Ace'
        total += 11
      elsif card[0].to_i == 0
        total += 10
      else
        total += card[0].to_i
      end
    end

    hand.select { |card| card[0] == 'Ace' }.count.times do
        total -= 10 if total > BLACKJACK
    end
    total
  end

  def display_card(card)
    suit = card[1].downcase
    value = card[0].downcase
    image = "<img src='/images/cards/#{suit}_#{value}.jpg' class='card'>"
  end

  def win(msg)
    session[:money] += session[:bet].to_i
    @success = "#{msg} You won #{session[:bet]}!"
  end

  def lose(msg)
    session[:money] -= session[:bet].to_i
    @error = "#{msg}, You lost #{session[:bet]}."
  end

  def tie(msg)
    @success = "#{msg}"
  end

  def blackjack(msg)
    blackjack_win = session[:bet].to_i * 1.5
    session[:money] += blackjack_win.to_i
    @success = "#{msg} You won #{(blackjack_win).to_i}!"
  end

  def toggle_buttons
    @show_hit_or_stay_buttons = false
    @play_again = true
  end

end

before do
  @show_hit_or_stay_buttons = true
  @show_dealer_button = false
end

get '/' do
  if session[:player_name]
    redirect '/bet'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Please enter a name."
    halt erb :new_player
  end

  session[:player_name] = params[:player_name]
  session[:money] = 1000
  redirect '/bet'
end

get '/bet' do
  erb :bet
end

post '/bet' do
  if session[:money] >= 1
    if params[:bet].to_i < 1
      @error = "Please enter a valid bet amount."
      halt erb :bet
    elsif params[:bet].to_i > session[:money]
      @error = "You do not have enough money!"
      halt erb :bet
    end
  else
    redirect '/bankrupt'
  end

  session[:bet] = params[:bet].to_i
  redirect '/game'
end

get '/game' do
  session[:deck] = initialize_deck
  session[:turn] = session[:player_name]

  session[:dealer_hand] = []
  session[:player_hand] = []
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop

  player_total = calculate_hand(session[:player_hand])
  dealer_total = calculate_hand(session[:dealer_hand])

  case
  when player_total == BLACKJACK
    blackjack("#{session[:player_name]} hit Blackjack!")
    toggle_buttons
  when player_total == BLACKJACK && dealer_total == BLACKJACK
    tie("It's a tie!")
    toggle_buttons
  end
  erb :game
end

post '/game/player/hit' do
  session[:player_hand] << session[:deck].pop
  player_total = calculate_hand(session[:player_hand])

  case
  when player_total == BLACKJACK
    win("#{session[:player_name]} hit Blackjack!")
    toggle_buttons
  when player_total > BLACKJACK
    lose("Sorry #{session[:player_name]} busted!")
    toggle_buttons
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
    lose("Dealer hit Blackjack!")
    toggle_buttons
  elsif dealer_total > BLACKJACK
    win("Dealer Busted!")
    toggle_buttons
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
    lose("Sorry #{session[:player_name]} lost!")
    toggle_buttons
  elsif player_total > dealer_total
    win("#{session[:player_name]} won!")
    toggle_buttons
  else
    tie("It's a tie!")
    toggle_buttons
  end

  erb :game
end

get '/game_over' do
  erb :game_over
end

get '/bankrupt' do
  erb :bankrupt
end
