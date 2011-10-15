#require 'citrus'
require 'polyglot'
require 'treetop'
require "chess/version"
require "chess/game"
require "chess/move"
require "chess/position"
require "chess/engine"
require "chess/engine_adapter"
require "chess/piece"
require "chess/piece/bishop"
require "chess/piece/king"
require "chess/piece/queen"
require "chess/piece/rook"
require "chess/piece/knight"
require "chess/piece/pawn"
require 'chess/client/base'
require "chess/client/fics"
require 'chess/pgn'

#Citrus.load File.dirname(__FILE__) + '/chess/pgn'

#Treetop.load File.dirname(__FILE__) + '/chess/pgn'

module Chess
    WHITE   = 0x0000
    BLACK   = 0x0100
    PAWN    = 0x0001
    KNIGHT  = 0x0002
    BISHOP  = 0x0003
    ROOK    = 0x0004
    KING    = 0x0005
    QUEEN   = 0x0006

    def algebraic_to_array(move_str)
      [move_str.lowercase[0].ord - 65, move_str[1].to_i]
    end
end
