class Card
	def self.getSuit num
		suit = num / 14
		case suit
		when 0
			"h"
		when 1
			"d"
		when 2
			"c"
		when 3
			"s"
		when 4
			"JOKER"
		else
			puts "SUIT UNDEFINED : " + suit.to_s
		end
	end

	def self.getValue num
		num = (num+2) % 14
		case num
		when 11
			"J"
		when 12
			"Q"
		when 13
			"K"
		when 14
			"A"
		else
			num.to_s
		end
	end

	def self.getShortName num
		suit = Card.getSuit num
		if suit != "JOKER"
			value = Card.getValue num
			value + suit
		else
			suit
		end
	end
end

class Deck

#	@faceup = True
	@contents = Array.new

	def setToCardDeck
		@contents = (0..53).to_a
	end

	def shuffle
		@contents.shuffle!
	end

	def drawCards num
		@contents.shift num
	end
end
