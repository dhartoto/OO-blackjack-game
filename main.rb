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

    session[:play_deck]   = []
    deck.each {|x| session[:play_deck] << x} # Initialize playing deck
    session[:play_deck].shuffle!

  end

  def init_deal
    session[:player_turn] = true
    session[:got_chips] = true
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
        x == 0? total += 10 : total += x
      end
      total    
    else
    # Calculation of hand with ace(s)
      # Step 1. Calculate cards without the aces
      hand.reject{|x| ace.include?(x)}.each do |x|
        x = x[0..-2].to_i
        x == 0? total += 10 : total += x
      end

      # Step 2. Add the value of ace(s) to the current total
      nr_ace = ace.length
      case nr_ace
        when 1 then total <= 10? total += 11 : total += 1
        when 2 then total <= 9? total += 12 : total += 2
        when 3 then total <= 8? total += 13 : total += 3
        else total <= 7? total += 14 : total += 4
      end
    total 
    end
  end

  def refresh
    session[:player_turn] = true
    session[:got_chips] = true
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

# ROUTES

get '/' do
  if session[:username]
    session[:wallet] = 500
    erb :index
  else
    redirect'/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  session[:wallet] = 500
  session[:username] = params[:username]
  redirect '/bet'
end

get '/bet' do
  erb :bet
end

post '/bet' do # CHECK WHEN WALLET = 0 and when BET > WALLET
  if params[:bet].to_i > session[:wallet]
    session[:got_chips] = false
    erb :bet
  else
    session[:got_chips] = true
    session[:bet] = params[:bet].to_i
    if session[:play_deck] != []
      init_deal
      session[:dealer_total] = calc(session[:dealer_hand])
      session[:player_total] = calc(session[:player_hand])
      if session[:player_total] == 21
        redirect '/game/player/win'
      else
        redirect '/game'
      end
    else
      init_game
      init_deal
      session[:dealer_total] = calc(session[:dealer_hand])
      session[:player_total] = calc(session[:player_hand])
      if session[:player_total] == 21
        redirect '/game/player/win'
      else
        redirect '/game'
      end
    end
  end
end

get '/game' do
    erb :game
end

post '/game/hit' do
  if session[:player_turn] == true
    # Player's turn:
    session[:player_hand] << hit
    session[:player_total] = calc(session[:player_hand])
    
    if session[:player_total] > 21
      redirect '/game/player/bust'
    else
      redirect '/game'
    end
  else
    #Dealer's turn:
    if session[:dealer_total] < 17      
      session[:dealer_hand] << hit
      session[:dealer_total] = calc(session[:dealer_hand])

      if session[:dealer_total] > 21
        redirect '/game/dealer/bust'
      else
        redirect '/game'
      end
    else
      if session[:dealer_total] >= session[:player_total]
        redirect '/game/dealer/win'
      else
        redirect '/game/player/win'
      end
    end
  end
end

post '/game/stay' do
  session[:player_turn] = false

  if session[:dealer_total] == 21
    redirect '/game/dealer/win'
  else
   redirect '/game'
  end
end

get '/game/player/bust' do
  erb :player_bust
end

post '/game/player/bust' do
  session[:wallet] -= session[:bet]
  redirect '/bet'
end

get '/game/player/win' do
  erb :player_win
end

post '/game/player/win' do
  session[:wallet] += session[:bet]
  redirect '/bet'
end

get '/game/dealer/win' do
  erb :dealer_win
end

get '/game/dealer/bust' do
  erb :dealer_bust
end

post '/replay' do
  refresh
  redirect '/'
end

post '/end' do
  refresh
  erb :end
end


