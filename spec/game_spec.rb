require 'spec_helper'
describe Chess::Game do
  it "should generate pgn string" do
    game = Chess::Game.new
    game.players[:white] = Chess::Player.new('Karpov')
    game.players[:black] = Chess::Player.new('Kasparov')
    game.make_move('e4')
    game.make_move('e5')
    game.result = "1/2-1/2"

    res = <<EOS
[Event "?"]
[Site "?"]
[Date "????.??.??"]
[Round "?"]
[White "Karpov"]
[Black "Kasparov"]
[Result "1/2-1/2"]
 
1. e4 e5 1/2-1/2
EOS

    game.to_pgn.should eql(res)
  end

  
  it "should create game from pgn" do
    #pending
    games = Chess::Game.load_pgn("spec/fixtures/game1.pgn")
    game = games[0]
    game.event.should eql("F/S Return Match")
    game.site.should eql("Belgrade, Serbia Yugoslavia|JUG")
    game.date.should eql("1992.11.04")
    game.round.should eql(29)
    game.result.should eql("1/2-1/2")
    game.white_player.name.should eql("Fischer, Robert J.")
    game.get_move(19, :white).description.should eql("exd6")
  end


  it "should get_move" do
    #pending
    game = Chess::Game.load_pgn("spec/fixtures/game1.pgn")[0]
    move = game.get_move(3, :white)
    move.description.should eql("Bb5")
  end

  it "should get positions from game" do
    #pending
    game = Chess::Game.load_pgn("spec/fixtures/game1.pgn")[0]
    move = game.get_move(3, :white)
    puts "got move #{move.inspect}"
    position = game.get_position(move)
    position.to_fen.should eql("r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 0 3")
  end

  it "should get variations" do
    #pending
    game = Chess::Game.load_pgn("spec/fixtures/test3.pgn")[0]
    move = game.get_move(19, :black)
    move.description.should eql("Nec8")
    move.variations[0][1].description.should eql("Qe3")
  end

  it "should parse multiple games" do
    games = Chess::Game.load_pgn("spec/fixtures/middleg.pgn")
    games.count.should eql(54)
  end

  it "should generate complete pgn" do
    pgn_text = File.read("spec/fixtures/test3.pgn")
    game = Chess::Game.from_pgn(pgn_text)
    game.to_pgn.should eql(pgn_text)
  end

  it "should do stuff" do
    pgn_text = File.read("/tmp/game.pgn")
    game = Chess::Game.from_pgn(pgn_text)
    puts game.inspect
  end
end


