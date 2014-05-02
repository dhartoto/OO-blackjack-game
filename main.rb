require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

helpers do

  def hit
    session[:play_deck].pop
  end

  def init_game
    deck = 
    ['KH', 'QH', 'JH', 'AH', '2H', '3H','4H',
     '5H', '6H', '7H', '8H', '9H', '10H',
     'KC', 'QC', 'JC', 'AC', '2C', '3C','4C',
     '5C', '6C', '7C', '8C', '9C', '10C',
     'KD', 'QD', 'JD', 'AD', '2D', '3D','4D',
     '5D', '6D', '7D', '8D', '9D', '10D',
     'KS', 'QS', 'JS', 'AS', '2S', '3S','4S',
     '5S', '6C', '7S', '8S', '9S', '10S']

    session[:play_deck] = []
    deck.each {|x| session[:play_deck] << x} # Initialize playing deck
    session[:play_deck].shuffle!
  end

  def init_deal
    session[:player_turn] = true
    session[:dealer_total] = 0
    session[:player_total] = 0
    session[:dealer_hand] = []
    session[:player_hand] = []
    2.times do
      session[:player_hand] << hit
      session[:dealer_hand] << hit
    end
  end

  def calc(hand)
    total = 0
    ace = hand.select {|x| x[0] == 'A'}
    # Calculation of hand without aces.
    if ace == []
      hand.each do |x|
        x = x[0..-2].to_i
        total += x == 0 ? 10 : x
      end
      total    
    else

    # Calculation of hand with ace(s)
      # Step 1. Calculate cards without the aces
      hand.reject{|x| ace.include?(x)}.each do |x|
        x = x[0..-2].to_i
        total += x == 0 ? 10 : x
      end

      # Step 2. Add the value of ace(s) to the current total
      nr_ace = ace.length
      case nr_ace
        when 1 then total += total <= 10 ? 11 : 1
        when 2 then total += total <= 9 ?  12 : 2
        when 3 then total += total <= 8 ?  13 : 3
        else total += total <= 7 ? 14 : 4
      end
    total 
    end
  end

  def refresh
    session[:player_turn] = true
    session[:gameover] = false
    session[:player_hand] = []
    session[:dealer_hand] = []
    session[:dealer_total] = 0
    session[:player_total] = 0
    session[:play_deck] = []
    session[:wallet] = 500
    session[:bet] = 0
  end

  def conv_to_img(card)
    suits  = {H: 'hearts', C: 'clubs', D: 'diamonds', S: 'spades'}
    royals = {K: 'king', Q: 'queen', J: 'jack', A: 'ace'}
    card_val  = card[0..-2]
    card_suit = card[-1]
    card_suit = suits[card_suit.to_sym]
    if card_val.to_i == 0
      royal = royals[card_val.to_sym]
      "<img src='/images/cards/#{card_suit}_#{royal}.jpg' class='thumbnail' style='width: 160px; height 234px'/>"
    else                        
      "<img src='/images/cards/#{card_suit}_#{card_val}.jpg' class='thumbnail' style='width: 160px; height 234px'/>"
    end
  end
end

before do

end

get '/' do
  if session[:username]
    session[:wallet] = 500
    erb :index
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:username].empty?
    @error = "Please enter your name."
    halt erb :new_player
  else
    session[:wallet] = 500
    session[:username] = params[:username]
    redirect '/bet'
  end
end

get '/bet' do
  if session[:wallet] == 0
    erb :replay
  else
    erb :bet
  end
end

post '/bet' do
  if params[:bet].to_i > session[:wallet]
    @error = "You do not have enough chips. Try a different amount"
    halt erb :bet
  elsif params[:bet].nil? || params[:bet].to_i == 0
    @error = "Please bet an amount greater than 0."
    halt erb :bet
  else
    session[:bet] = params[:bet].to_i
    session[:gameover] = false
    redirect '/game/init'
  end
end

get '/game/init' do
  if session[:play_deck] == nil || session[:play_deck] == []
    init_game
    init_deal
  else
    init_deal
  end
    session[:dealer_total] = calc(session[:dealer_hand])
    session[:player_total] = calc(session[:player_hand])
    redirect '/game'
end

get '/game' do
  if session[:player_total] == 21
    @win = "Blackjack! Congratulations, you win!"
    session[:wallet] += session[:bet]
    session[:gameover] = true
  end
    erb :game
end

post '/game/hit' do
  if session[:player_turn]
    session[:player_hand] << hit
    session[:player_total] = calc(session[:player_hand])
    # redirect '/game'
    if session[:player_total] == 21
      @win = "Blackjack! Congratulations, you win!"
      session[:wallet] += session[:bet]
      session[:gameover] = true

    elsif session[:player_total] > 21
      @lose = "You bust! Dealer wins!"
      session[:wallet] -= session[:bet]
      session[:gameover] = true
    end
    erb :game, layout: false

  else

    if session[:dealer_total] < 17  
      session[:dealer_hand] << hit
      session[:dealer_total] = calc(session[:dealer_hand])
      redirect '/game/dealer'
    else
      redirect '/game/compare'
    end
  end
end

post '/game/stay' do
  session[:player_turn] = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  if session[:dealer_total] == 21
    @lose = "Blackjack! Dealer wins!"
    session[:wallet] -= session[:bet]
    session[:gameover] = true
    erb :game, layout: false

  elsif session[:dealer_total] > 21
    @win = "Dealer bust! You win!"
    session[:wallet] += session[:bet]
    session[:gameover] = true
    erb :game, layout: false

  else
    erb :game, layout: false
  end
end

get '/game/compare' do
  if session[:dealer_total] > session[:player_total]
    @lose = "Dealer wins with a hand of #{session[:dealer_total]}"
    session[:wallet] -= session[:bet]
    session[:gameover] = true
    erb :game, layout: false
  elsif session[:dealer_total] == session[:player_total]
    @win = "It's a draw! There are no winners or losers in this round."
    session[:gameover] = true
    erb :game, layout: false
  else
    @win = "Congratulations! You win with a total of #{session[:player_total]}"
    session[:wallet] += session[:bet]
    session[:gameover] = true
    erb :game, layout: false
  end  
end

post '/replay' do
    refresh
    redirect '/'
end

post '/end' do
  refresh
  erb :end
end