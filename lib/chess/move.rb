class Chess::Move
  attr_accessor :number, :source, :target, :player, :annotation, :piece, :description, :is_castle_short, :is_castle_long, :is_en_passant, :promotion, :capture, :position, :parent, :previous,  :next, :is_null, :numeric_annotations, :variation_moves

  ANNOTATIONS = {
    0 => 'foo',
    1 => 'bar'
  }
  def initialize(from = nil, to = nil)
    if from.nil?
      @is_null = true
    end
    if from.kind_of?(String)
      @source = Chess.algebraic_to_array(from)
    else
      @source = from
    end
    if to.kind_of?(String)
      @target = Chess.algebraic_to_array(to)
    else
      @target = to
    end
    @variation_moves = []
    @numeric_annotations = []
  end

  def is_castle_short?
    unless @piece.kind_of?(Chess::Piece::King)
      return false
    end
    if (source == [0,4] && target == [0,6]) || ( source == [7,4] && target == [7,6])
      true
    else
      false
    end
  end

  def variations
    #return @variations if @variations
    @variations = []
    variation_moves.each do |mv|
      var = [mv]
      while(mv = mv.next)
        var << mv
      end
      @variations << var
    end
    @variations
  end

  def full_annotation
    str = self.annotation ? self.annotation.dup : ''
    str << "\n"
    self.numeric_annotations.each do |i|
      if ANNOTATIONS[i]
      str << ANNOTATIONS[i]
      str << "\n"
      end
    end
    str
  end
  def is_castle_long?
    unless @piece.kind_of?(Chess::Piece::King)
      return false
    end
    if (source == [0,4] && target == [0,2]) || ( source == [7,4] && target == [7,2])
      true
    else
      false
    end
  end

  def algebraic
    src_sq = Chess::Position.indexes_to_algebraic(source[0], source[1])
    dest_sq = Chess::Position.indexes_to_algebraic(target[0], target[1])
    "#{src_sq}#{dest_sq}"

  end

  def to_s
    return description if description
    algebraic
  end

  def full_string
    str = ''
    if self.player == :white
      str << " #{@number}. "
    end
    str << to_s
    numeric_annotations.each do |i|
      str << " $#{i}"
    end

    if annotation
      str << " {#{annotation}}"
    end
    
    if variations
      variations.each do |var|
        str << " ("
        if var.first.player == :black
          str << "#{var.first.number}... "
        end
        var.each do |move|
          str << "" + move.full_string + " "
        end
        str << ") "
      end
    end
    str
  end
end

