require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

helpers do
  def calculate_total(cards)
    # [['H', '3'], ['S', 'Q'], ... ]
    arr = cards.map{|e| e[1] }

    total = 0
    arr.each do |value|
      if value == "A"
        total += 11
      elsif value.to_i == 0 # J, Q, K
        total += 10
      else
        total += value.to_i
      end
    end

    #correct for Aces
    arr.select{|e| e == "A"}.count.times do
      total -= 10 if total > 21
    end

    total
  end


  def card_image(card)
    suit = case card[0]
      when "H" then "hearts"
      when "D" then "diamonds"
      when "C" then "clubs"
      when "S" then "spades"
    end

    value = card[1]
    if ["J", "Q", "K", "A"].include?(value)
      value = case card[1]
        when "J" then "jack"
        when "Q" then "queen"
        when "K" then "king"
        when "A" then "ace"
      end
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end
end

before do
  @show_hit_or_stay_button = true
end

get '/' do
  #if user?
    #go to the game
  #else redirect to new player form

  if session[:player_name]
    redirect "/game"
  else
    redirect "/new_player"
  end
end

get "/new_player" do
  erb :new_player
end

post "/new_player" do
  if params[:player_name].empty?
    @error = "Name is required."
    halt erb :new_player
  end

  session[:player_name] = params[:player_name]
  redirect "/game"
end

get "/game" do
  #deck
  suits = ['H', 'D', 'S', 'C']
  value = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(value).shuffle!
  #deal cards
  session[:dealer_cards] = []
  session[:player_cards] = []

  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

    #dealer + player cards
  erb :game
end

post "/game/player/hit" do
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total == 21
    @success = "Congratulation! #{session[:player]} hit black jack."
    @show_hit_or_stay_button =false


  elsif calculate_total(session[:player_cards]) > 21
    @error = "Sorry, #{session[:player_name]} busted!"
    @show_hit_or_stay_button = false
  end


  erb :game
end

post "/game/player/stay" do
  @success = "#{session[:player_name]} chose to stay."
  @show_hit_or_stay_button = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  @show_hit_or_stay_button = false

  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == 21
    @error = "Sorry, Dealer hit black jack."
  elsif dealer_total > 21
    @success = "Congratulation!, dealer busted. You won."
  elsif dealer_total >= 17
    #stay
    redirect '/game/compare'
  else
    #hit
    @show_dealer_hit_button = true
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end


get '/game/compare' do
  @show_hit_or_stay_button = false

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    @error ="Sorry, you lost."
  elsif player_total > dealer_total
    @success = "Congratulation, you won."
  else
    @success = "Tie."
  end

  erb :game
end
# post '/set_name' do
#   session[:player_name] = params[:player_name]
#   redirect "/game"

# end

# get "/game" do
#   session[:deck] = [["2", "H"], ["3", "D"]]
#   session[:player_cards] = []
#   session[:player_cards] << session[:deck].sample

#   erb :game
# end
