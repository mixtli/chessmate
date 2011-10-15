require 'spec_helper'
describe Chess::Position do
  it "should create position from fen" do
    position = Chess::Position.from_fen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
    position.squares[0][0].should be_kind_of(Chess::Piece::Rook)
    position.squares[0][0].color.should eql(:white)
  end

  it "should create complex position from fen" do
    position = Chess::Position.from_fen('r1bq1rk1/4bppp/p1n2n2/1pppp3/4P3/2PP1N2/PPB2PPP/R1BQRNK1 w - - 0 1')
    puts position.to_str
    position.to_fen.should eql('r1bq1rk1/4bppp/p1n2n2/1pppp3/4P3/2PP1N2/PPB2PPP/R1BQRNK1 w - - 0 1')
  end

  it "should find pieces" do
    position = Chess::Position.initial
    #puts position.to_str
    white_pawns = position.find_pieces(Chess::Piece::Pawn,  :white)
    white_pawns.should eql([[1,0],[1,1],[1,2],[1,3],[1,4],[1,5],[1,6],[1,7]])
    black_pawns = position.find_pieces(Chess::Piece::Pawn, :black)
    black_pawns.should eql([[6,0],[6,1],[6,2],[6,3],[6,4],[6,5],[6,6],[6,7]])
    white_knights = position.find_pieces(Chess::Piece::Knight, :white)
    white_knights.should eql([[0,1],[0,6]])
  end

  it "should create a move given a move string" do
    position = Chess::Position.from_fen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
    move = position.create_move("e4")
    move.player.should eql(:white)
    move.source.should eql([1,4])
    move.target.should eql([3,4])
  end
  # rQk2K2/8/8/8/8/8/8/8 w - - 0 1
  #

  it "should generate a proper fen" do
    position = Chess::Position.initial
    position.to_fen.should eql("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
  end
end

