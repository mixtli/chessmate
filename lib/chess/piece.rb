module Chess::Piece
  class Base
    attr_accessor :color
    def initialize(color)
      self.color = color
    end
  end
end
