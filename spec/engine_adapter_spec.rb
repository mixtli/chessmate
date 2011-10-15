require 'spec_helper'
describe Chess::EngineAdapter do
  before(:all) do
    @engine = Chess::EngineAdapter.new
    @engine.executable = "gnuchess --uci"
    @engine.run
    sleep 5
  end
  after(:all) do
    @engine.stop
    puts "stopped"
    @engine.kill
    puts "killed"
  end
  it "should process isready" do
    @engine.readyok.should be(false)
    @engine.isready
    sleep 1
    @engine.readyok.should be(true)
  end

  it "should get a move" do
    @engine.position("8/8/8/8/3r1k2/3q4/3B4/4K3 b - - 0 1")
    @engine.go(:btime => 1000)
    sleep 3
    @engine.move.description.should eql("d3d2")
    puts @engine.move
    puts "still here"    
  end

  it "should get readyok" do
    @engine.isready
    sleep 1
    @engine.readyok.should be(true)
  end

  it "should process options" do
    @engine.uci
    sleep 2
    @engine.options['History Pruning'][:type].should eql("check")
    puts @engine.options.inspect
  end

end

