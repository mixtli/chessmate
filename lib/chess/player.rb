class Chess::Player
  attr_accessor :name, :elo, :type, :engine

  def initialize(name = 'Player 1', args = {})
    @name = name
    @type = args[:type] || :human
    @engine = args[:engine] 
  end
  def to_s
    name
  end


end
