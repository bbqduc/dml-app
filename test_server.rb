require 'em-websocket'
require 'json'
require './card'


# State for game EXCLUDING states of individual players


class GameDecks
	@event = Deck.new
	@marketplace = Array.new # 3-4
	@blackmarket = Array.new # 0-3
	@nest = Deck.new
	@removed = Deck.new

	def populateMarket

	end
end

class Player
	@id
	@connection
	@playerdecks

	def initialize ws, id
		@connection = ws
		@id = id
		@connection.send "You got the ID : " + id.to_s
	end
end

class Game

	def AddPlayer ws
		id = @players.length
		@players.push Player.new ws, id
	end

	def initialize
		@players = Array.new
		@gamedecks = GameDecks.new
	end
end

game = Game.new

EM.run {
  EM::WebSocket.run(:host => "0.0.0.0", :port => 8080) do |ws|

    ws.onopen { |handshake|
      puts "WebSocket connection open"

      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client
      ws.send "Hello Client, you connected to #{handshake.path}"

	  game.AddPlayer ws

#	  cardnames = Array.new
#	  cards = deck.drawCards 5
#	  cards.each do |c|
#		  cardnames << (Card.getShortName c)
#	  end
#	  asd = {:cards => cardnames}
#	  ws.send asd.to_json
    }

    ws.onclose { puts "Connection closed" }

    ws.onmessage { |msg|
      puts "Received message: #{msg}"
      ws.send "Pong: #{msg}"
    }
  end
}
