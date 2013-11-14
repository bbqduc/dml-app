require 'em-websocket'
require 'json'
require './card'
require 'sanitize'


# State for game EXCLUDING states of individual players


class GameDecks
	attr_accessor :event
	attr_accessor :marketplace
	attr_accessor :blackmarket
	attr_accessor :removed
	attr_accessor :nest

	def populateMarket

	end

	def initialize
		@event = Deck.new
		@event.setToCardDeck
		@event.shuffle

		@marketplace = Deck.new
		@blackmarket = Deck.new
		@next = Deck.new
		@removed = Deck.new
	end
end

class Player
	attr_reader :id 
	attr_accessor :connection
	attr_accessor :hand
	attr_accessor :emblems

	def initialize ws, id
		@connection = ws
		@id = id
		@hand = Deck.new
		@emblems = Deck.new
	end

	def SendMessage msg
		@connection.send msg
	end
end

class Game

	def AddPlayer ws
		id = @players.length
		@players << (Player.new ws, id)
		@players[id].hand.TakeFrom @gamedecks.event, 5
		SendLogMessage @players[id], "You got the ID : " + id.to_s
		SendLogMessage @players[id], "Herpsun derp!"

		ws.onmessage { |msg|
			HandleMessage @players[id], msg
			puts "Received message: #{msg}"
		}

		SendGlobalLogMessage "Player #{id} connected."
	end

	def HandleMessage player, message
		begin
			message = JSON.parse message
		rescue JSON::ParserError
			puts "Non-JSON message received : " + message
			return
		end
		case message["type"]
		when "chat"
			puts "Received chat message #{message['message']}"
			broadcast = {:message => Sanitize.clean(message["message"]), :type => "chat"}
			SendGlobalMessage broadcast.to_json
		end

	end

	def SendGlobalMessage msg
		@players.each do |p|
			p.SendMessage msg
		end
	end

	def initialize
		@players = Array.new
		@gamedecks = GameDecks.new
	end

	def SendState

	end

	def SendLogMessage player, msg
		tmp = {:type => "logmessage", :message => msg}.to_json
		player.connection.send tmp
	end

	def SendGlobalLogMessage msg
		tmp = {:type => "logmessage", :message => msg}.to_json
		SendGlobalMessage tmp
	end
end

game = Game.new

deck = Deck.new
deck.setToCardDeck
deck.shuffle

EM.run {
  EM::WebSocket.run(:host => "0.0.0.0", :port => 8080) do |ws|

    ws.onopen { |handshake|
      puts "WebSocket connection open"

      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client

	  game.AddPlayer ws

	  cardnames = Array.new
	  cards = deck.drawCards 5
	  cards.each do |c|
		  cardnames << (Card.getShortName c)
	  end
	  asd = {:cards => cardnames, :type => "cards"}
	  ws.send asd.to_json
    }

    ws.onclose { puts "Connection closed" }

    ws.onmessage { |msg|
      puts "Received message: #{msg}"
#      ws.send "Pong: #{msg}"
    }
  end
}
