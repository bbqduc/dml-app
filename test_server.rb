require 'em-websocket'
require 'json'
require './card'
require 'sanitize'
require 'ruby-poker'

# State for game EXCLUDING states of individual players

class PokerPlayer
	attr_reader :id 
	attr_accessor :connection
	attr_accessor :hand

	def initialize ws, id
		@connection = ws
		@id = id
		@hand = Deck.new
	end

	def SendMessage msg
		@connection.send msg
	end

    def name
        id.to_s
    end
end

class PokerGame
    def initialize
        @deck = Deck.new
        @board = Deck.new
        @players = Array.new
    end

    def BeginHand
        SendGlobalLogMessage "Beginning Hand"
        @deck = Deck.new
        @deck.setToCardDeck
        @board = Deck.new
        @deck.shuffle

        @players.each do |p|
            p.hand = Deck.new
            p.hand.TakeFrom @deck, 2
        end
    end

    def Flop
        SendGlobalLogMessage "Dealing Flop"
        @board.TakeFrom @deck, 3
    end

    def Turn
        SendGlobalLogMessage "Dealing Turn"
        @board.TakeFrom @deck, 1
    end

    def River
        SendGlobalLogMessage "Dealing River"
        @board.TakeFrom @deck, 1
    end

    def SendState
        boardstr = @board.contents.map { |x| Card.getShortName x }.join " "

        @players.each do |p|
            handstr = p.hand.contents.map { |x| Card.getShortName x }.join " "
            tmp = {:type => "state", :board => boardstr, :hand => handstr}.to_json
            p.SendMessage tmp
        end
    end

    def RunHand
        if @players.length == 0
            return
        end
        BeginHand()
        SendState()
        sleep 5
        Flop()
        SendState()
        sleep 5
        Turn()
        SendState()
        sleep 5
        River()
        SendState()
        sleep 5
        AnnounceWinner()
    end

    def AnnounceWinner
        pokerhands = []
        @players.each do |p|
            p.hand.contents += @board.contents
            phandstr = p.hand.contents.map { |x| Card.getShortName x }.join " "
            h = PokerHand.new phandstr
            tmp = {:hand => h, :name => p.name}
            pokerhands << tmp
        end

        pokerhands.sort_by! { |k| k[:hand]}
        winmsg = pokerhands.last[:name] + " won with hand " + pokerhands.last[:hand].to_s
        
        SendGlobalLogMessage winmsg
    end

	def AddPlayer ws
		id = @players.length
		@players << (PokerPlayer.new ws, id)
		SendLogMessage @players[id], "You got the ID : " + id.to_s
		SendLogMessage @players[id], "Herpsun derp!"

		ws.onmessage { |msg|
			HandleMessage @players[id], msg
			puts "Received message: #{msg}"
		}

		ws.onclose { 
			HandleDisconnect @players[id]
		}

		SendGlobalLogMessage "Player #{id} connected."
	end

	def HandleDisconnect player
		#todo : can't yet remove from @players since it's a dumb array
		SendGlobalLogMessage "Player #{player.id} disconnected."
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

game = PokerGame.new

thr = Thread.new { 
    while true
        game.RunHand
        sleep 5
    end
}

EM.run {
  EM::WebSocket.run(:host => "0.0.0.0", :port => 8080) do |ws|

    ws.onopen { |handshake|
      puts "WebSocket connection open"

      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client

	  game.AddPlayer ws
    }

  end

}

#thr.join

