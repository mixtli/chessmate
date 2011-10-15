#
#  Position.rb
#  iChess
#
#  Created by Ron McClain on 9/10/11.
#  Copyright 2011 __MyCompanyName__. All rights reserved.
#

module Chess
  class Position
    attr_accessor :squares, :move_number, :to_play, :castling, :en_passant_square, :halfmove_clock, :castling_rights
    def initialize
        @squares = []
        0.upto(7) do |i|
            @squares[i] = []
            0.upto(7) do |j|
              @squares[i][j] = nil
            end
        end
        @move_number = 0
        @to_play = :white
        @castling = 'KQkq'
        @castling_rights = {
          :white => {
            :king => true,
            :queen => true
          },
          :black => {
            :king => true,
            :queen => true
          }
        }
        @en_passant_square = nil
        @halfmove_clock = 0
    end
    

    def castling_string
      str = ''
      if @castling_rights[:white][:king]
        str << 'K'
      end
      if @castling_rights[:white][:queen]
        str << 'Q'
      end
      if @castling_rights[:black][:king]
        str << 'k'
      end
      if @castling_rights[:black][:queen]
        str << 'q'
      end
      if str == ''
        str = '-'
      end
      str
    end

    def initialize_copy(source)
      super
      @squares = []
      @castling_rights = {
        :white => {
          :king => source.castling_rights[:white][:king],
          :queen => source.castling_rights[:white][:queen]
        },
        :black => {
          :king => source.castling_rights[:black][:king],
          :queen => source.castling_rights[:black][:queen]
        }
      }
      0.upto(7) do |i|
        @squares[i] = []
        0.upto(7) do |j|

          @squares[i][j] = if source.squares[i][j]
                             source.squares[i][j].clone
                           else
                             nil
                           end
        end
      end
    end

    def self.initial
      from_fen('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1')
    end
    
    def set_square(i, j, piece)
      #HotCocoa.alert :message => "Setting square #{i}, #{j} to #{piece}"
      @squares[i][j] = piece
    end

    def can_castle?(side)
      # check whether king or rook has moved
      return false unless has_castling_rights?(@to_play, side)
      # check whether anything in the way
      if(@to_play == :white)
        if side == :king
          if @squares[0][5] || @squares[0][6]
            return false
          end
          if square_attacked?([0,5], :black) || square_attacked?([0,6], :black)
            return false
          end
        else
          if @squares[0][1] || @squares[0][2] || @squares[0][3]
            return false
          end
          if square_attacked?([0,1], :black) || square_attacked?([0,2], :black) || square_attacked?([0,3], :black)
            return false
          end
        end
      else
        if side == :king
          if @squares[7][5] || @squares[7][6]
            return false
          end
          if square_attacked?([7,5], :white) || square_attacked?([7,6], :white)
            return false
          end
        else
          if @squares[7][1] || @squares[7][2] || @squares[7][3]
            return false
          end
          if square_attacked?([7,1], :white) || square_attacked?([7,2], :white) || square_attacked?([7,3], :white)
            return false
          end
        end
      end
      if is_check?
        return false
      end

      true
    end

    def has_castling_rights?(player, side)
      return @castling_rights[player][side]
    end

    def build_move(source, target)
      move = Chess::Move.new(source, target)
      move.piece = @squares[source[0]][source[1]]
      if @squares[target[0]][target[1]]
        move.capture = true
      end
      move.player = @to_play
      move.position = self

      if target == @en_passant_square && @squares[source[0]][source[1]].kind_of?(Chess::Piece::Pawn)
        if @to_play == :white
          if source[0] == 4 && (target[1] == source[1] - 1 || target[1] == source[1] + 1)
            move.is_en_passant = true
          end
        else
          if source[0] == 3 && (target[1] == source[1] - 1 || target[1] == source[1] + 1)
            move.is_en_passant = true
          end
        end
      end
      #puts "got move #{move.inspect} piece #{move.piece}"
      move.number = self.move_number 

      str = case move.piece
            when Chess::Piece::Queen
              'Q'
            when Chess::Piece::King
              'K'
            when Chess::Piece::Rook
              'R'
            when Chess::Piece::Bishop
              'B'
            when Chess::Piece::Knight
              'N'
            when Chess::Piece::Pawn
              if move.capture
                (source[1] + 97).chr
              else
                ''
              end
            end

      str << "#{(target[1] + 97).chr}#{target[0] + 1}"
      move.description = str
      move
    end

    def self.from_fen(fen)
      position = Position.new
      ranks_str, move_str, castle_str, en_passant_str, half_move_num, full_move_num = fen.split(' ')
      rank_strs = ranks_str.split('/')
      rank_strs.reverse.each_with_index do |rank_str, i|
        j = 0
        rank_str.each_char do |chr|
          if chr =~ /\d/
            j += chr.to_i
          else

            position.set_square(i, j, chr_to_piece(chr))
            j += 1
          end
        end
      end
      position.to_play = case move_str
      when 'w'
         :white
      when 'b'
         :black
      end
      position.clear_castling_rights
      if castle_str =~ /k/
        position.castling_rights[:black][:king] = true
      end
      if castle_str =~ /q/
        position.castling_rights[:black][:queen] = true
      end
      if castle_str =~ /K/
        position.castling_rights[:white][:king] = true
      end
      if castle_str =~ /Q/
        position.castling_rights[:white][:queen] = true
      end

      unless en_passant_str == '-'
        position.en_passant_square = algebraic_to_indexes(en_passant_str)
      end
      position.move_number = full_move_num.to_i
      position.halfmove_clock = half_move_num.to_i
      position
    end

    def clear_castling_rights
      @castling_rights = { :white => {:king => false, :queen => false}, :black => {:king => false, :queen => false}}
    end

    def self.algebraic_to_indexes(square)
      [square[0].ord - 65, square[1].to_i]
    end
    def self.indexes_to_algebraic(i, j)
      "#{(j + 97).chr}#{i + 1}"
    end
    
    def self.chr_to_piece(chr)
      case chr
      when 'r'
        Chess::Piece::Rook.new(:black)        
      when 'n'
        Chess::Piece::Knight.new(:black)
      when 'b'
        Chess::Piece::Bishop.new(:black)
      when 'k'
        Chess::Piece::King.new(:black)
      when 'q'
        Chess::Piece::Queen.new(:black)
      when 'p'
        Chess::Piece::Pawn.new(:black)
      when 'R'
        Chess::Piece::Rook.new(:white)        
      when 'N'
        Chess::Piece::Knight.new(:white)
      when 'B'
        Chess::Piece::Bishop.new(:white)
      when 'K'
        Chess::Piece::King.new(:white)
      when 'Q'
        Chess::Piece::Queen.new(:white)
      when 'P'
        Chess::Piece::Pawn.new(:white)
      end
    
    end

    def self.piece_to_chr(piece)
      if piece.color == :white
        case piece
        when Chess::Piece::Rook
         'R'
        when Chess::Piece::Knight
         'N'
        when Chess::Piece::Bishop
         'B'
        when Chess::Piece::King
         'K'
        when Chess::Piece::Queen
         'Q'
        when Chess::Piece::Pawn
         'P'
        end
      else
        case piece
          
        when Chess::Piece::Rook
         'r'
        when Chess::Piece::Knight
         'n'
        when Chess::Piece::Bishop
         'b'
        when Chess::Piece::King
         'k'
        when Chess::Piece::Queen
         'q'
        when Chess::Piece::Pawn
         'p'
        end
      end
    end 
    
    def to_fen
      rank_strs = []
      @squares.each_with_index do |rank, i|
        blank_count = 0
        str = ''
        rank.each do |piece|
          if piece.nil?
            blank_count += 1
          else
            if blank_count != 0
              str << blank_count.to_s
            end
            blank_count = 0
            str << self.class.piece_to_chr(piece)
          end
        end
          if blank_count != 0
            str << blank_count.to_s
          end
        rank_strs << str
      end
      ep_square = en_passant_square ? self.class.indexes_to_algebraic(en_passant_square[0], en_passant_square[1]) : '-'
      "#{rank_strs.reverse.join('/')} #{to_play_str} #{castling_string} #{ep_square} #{halfmove_clock} #{move_number}"
    end
    
    def to_play_str
      case to_play
      when :white
        'w'
      when :black
        'b'
      end
    end

    def create_castle_short_move
      move = if @to_play == :white
        build_move([0,4], [0,6])
      else
        build_move([7,4], [7,6])
      end
      move.description = 'O-O'
      move
    end

    def create_castle_long_move
      move = if @to_play == :white
        build_move([0,4], [0,2])
      else
        build_move([7,4], [7,2])
      end
      move.description = 'O-O-O'
      move
    end

    def create_move(move_str)
      #puts "create_move #{move_str} #{self.to_fen}"
      if(move_str == 'O-O') 
        return create_castle_short_move
      end
      if(move_str == 'O-O-O')
        return create_castle_long_move
      end

      if(move_str == '--')
        # Create NULL move
        move = Chess::Move.new(nil)
        move.player = self.to_play
        move.number = self.move_number
        move.description = '--'
        move.position = self
        return move
      end

      mv = move_str =~ /(.*)(\w)(\d)/
      first_part = $1
      target_rank = $3.to_i - 1
      target_file = $2.ord - 97 
      source_rank = nil
      source_file = nil
      capture = false
      target_square = "#{$2}#{$3}"
      if first_part =~ /x/
        first_part.sub!("x", "")
        capture = true
      end
      promotion = nil
      if move_str =~ /=(\w)/
        promotion = case $1
                    when 'N'
                      Chess::Piece::Knight
                    when 'Q'
                      Chess::Piece::Queen
                    when 'R'
                      Chess::Piece::Rook
                    when 'B'
                      Chess::Piece::Bishop
                    end
      end

      piece_letter = first_part.match(/[RNKQB]/)
      letter = nil
      if piece_letter
        first_part.sub!(piece_letter[0], "")
        letter = piece_letter[0]
      end
      rank_chr = first_part.match(/\d/)
      file_chr = first_part.match(/[a-h]/)
      piece_class = case letter
              when 'N'
                Chess::Piece::Knight
              when 'R'
                Chess::Piece::Rook
              when 'K'
                Chess::Piece::King
              when 'B'
                Chess::Piece::Bishop
              when 'Q'
                Chess::Piece::Queen
              else
                Chess::Piece::Pawn
              end
      piece = piece_class.new(@to_play)
      if file_chr
        source_file = file_chr[0].ord - 97
      end
      if rank_chr
        source_rank = rank_chr[0].to_i - 1
      end

      if piece.kind_of?(Chess::Piece::Pawn) && !capture
        source_file = target_file
        source_rank = nil
        #check double pawn move
        if (@to_play == :white && target_rank == 3) || (@to_play == :black && target_rank == 4)
          if @to_play == :white
            if squares[2][source_file].kind_of?(Chess::Piece::Pawn) &&  squares[2][source_file].color == :white
              source_rank = 2
            elsif squares[1][source_file].kind_of?(Chess::Piece::Pawn) && squares[1][source_file].color == :white
              source_rank = 1
            end
          else
            if squares[5][source_file].kind_of?(Chess::Piece::Pawn) && squares[5][source_file].color ==  :black
              source_rank = 5
            elsif squares[6][source_file].kind_of?(Chess::Piece::Pawn) &&  squares[6][source_file].color ==  :black
              source_rank = 6
            end
          end
        end
        unless source_rank
          if @to_play == :white
            source_rank = target_rank - 1
          else
            source_rank = target_rank + 1
          end
        end
      end

      if piece.kind_of?(Chess::Piece::Pawn) && capture
        # check for en passant
        if(@to_play == :white && target_rank == 4)
        elsif(@to_play == :black && target_rank == 5)
        end

        if @to_play == :white
          source_rank == target_rank - 1
        else
          source_rank == target_rank + 1
        end
      end


      possible_sources = []
      if !source_rank || !source_file 
        possible_sources = find_pieces(piece.class, @to_play, source_rank, source_file) 
      else
        possible_sources = [[source_rank, source_file]]
      end
      #puts "possible_sources = #{possible_sources.inspect}"
      possible_sources.each do |src|
        #puts "possible source = #{src.inspect}"
        move = build_move(src, [target_rank, target_file])
        move.description = move_str
        move.promotion = promotion
        #puts "checking #{move.inspect}"
        if is_legal?(move)
          return move
        end
      end
      return nil
    end

    def is_castle_short?(move)
      if @squares[move.source[0]][move.source[1]].kind_of?(Chess::Piece::King)
        if (move.source == [0,4] && move.target == [0,6]) || (move.source == [7,4] && move.target == [7,6])
          return true
        end
      end
      false
    end
    def is_castle_long?(move)
      if @squares[move.source[0]][move.source[1]].kind_of?(Chess::Piece::King)
        if (move.source == [0,4] && move.target == [0,2]) || (move.source == [7,4] && move.target == [7,2])
          return true
        end
      end
      false
    end

    def new_position_from_move(move)
      new_position = self.clone
      new_position.en_passant_square = nil

      # Handle NULL move
      if move.is_null
        new_position.to_play = self.to_play == :white ? :black : :white
        if new_position.to_play == :white
          new_position.move_number += 1
        end
        return new_position
      end

      # Handle castling
      if is_castle_short?(move)
        if @to_play == :white
          new_position.squares[0][7] = nil
          new_position.squares[0][5] = Chess::Piece::Rook.new(:white)
        else
          new_position.squares[7][7] = nil
          new_position.squares[7][5] = Chess::Piece::Rook.new(:black)
        end
      end
      if is_castle_long?(move)
        if @to_play == :white
          new_position.squares[0][0] = nil
          new_position.squares[0][3] = Chess::Piece::Rook.new(:white)
        else
          new_position.squares[7][0] = nil
          new_position.squares[7][3] = Chess::Piece::Rook.new(:black)
        end
      end

      # Special handling for en-passant
      if move.piece.kind_of?(Chess::Piece::Pawn)
        if move.source[0] == 1 && move.target[0] == 3
          new_position.en_passant_square = [2, move.source[1]]
        elsif move.source[0] == 6 && move.target[0] == 4
          new_position.en_passant_square = [5, move.source[1]]
        end

        if move.target == @en_passant_square
          if @to_play == :white
            if move.source[0] == 4 && (move.target[1] == move.source[1] - 1 || move.target[1] == move.source[1] + 1)
              new_position.squares[move.target[0] - 1][move.target[1]] = nil
            end
          else
            if move.source[0] == 3 && (move.target[1] == move.source[1] - 1 || move.target[1] == move.source[1] + 1)
              new_position.squares[move.target[0] + 1][move.target[1]] = nil
            end
          end
        end
      end

      # Do actual piece movement 
      piece = @squares[move.source[0]][move.source[1]]
      new_position.squares[move.source[0]][move.source[1]] = nil
      new_position.squares[move.target[0]][move.target[1]] = piece


      # Handle pawn promotion
      if(move.promotion)
        piece = move.promotion.new(@to_play)
        new_position.squares[move.target[0]][move.target[1]] = piece
      end

      # Reset Turn 
      new_position.to_play = @to_play == :white ? :black : :white

      if new_position.to_play == :white
        new_position.move_number += 1
      end


      # reset castling rights
      if(move.source == [0,0])
        new_position.castling_rights[:white][:queen] = false
      end
      if(move.source == [0,7])
        new_position.castling_rights[:white][:king] = false
      end
      if(move.source == [0,4])
        new_position.castling_rights[:white][:queen] = false
        new_position.castling_rights[:white][:king] = false
      end
     
      if(move.source == [7,0])
        new_position.castling_rights[:black][:queen] = false
      end
      if(move.source == [7,7])
        new_position.castling_rights[:black][:king] = false
      end
      if(move.source == [7,4])
        new_position.castling_rights[:black][:queen] = false
        new_position.castling_rights[:black][:king] = false
      end
     
      new_position
    end

    def find_pieces(type, color, row = nil, col = nil)
      pieces = []
      if row
        squares[row].each_with_index do |sq, idx|
          if sq && (type.nil? || sq.class == type) && color == sq.color
            pieces << [row, idx]
          end
        end
      elsif col
        squares.collect {|rank| rank[col]}.each_with_index do |sq, idx|
          if sq && (type.nil? || sq.class == type) && color == sq.color
            pieces << [idx, col]
          end
        end

      else
        squares.each_with_index do |rank, i|
          rank.each_with_index do |sq, j|

            if sq && (type.nil? || sq.class == type) && color == sq.color
              pieces << [i, j]
            end
          end
        end

      end
      return pieces 
      
    end

    def to_str
      str = ''
      7.downto(0) do |i|
        str << "\n"
        0.upto(7) do |j|
           chr = squares[i][j] ? self.class.piece_to_chr(squares[i][j]) : '.'
          str << " #{chr}"
        end
      end
      str
    end

    def invalid_move(move, error_str)
      puts move.description
      puts error_str
    end
    def is_legal?(move, flags = {})
      source = move.source
      target = move.target
      source_square = @squares[source[0]][source[1]]
      target_square = @squares[target[0]][target[1]]
      player = flags[:player] || @to_play
      unless source_square
        # no piece on square
        invalid_move(move, "INVALID MOVE: no piece on square")
        return false
      end
      unless (source_square.color == player)
        # wrong color
        invalid_move(move, "INVALID MOVE: wrong color")
        return false
      end
      if target_square && target_square.color == player
        invalid_move(move, "INVALID MOVE: cannot capture own piece")
        return false
      end

      if source[0] < 0 || source[0] > 7 || source[1] < 0 || source[1] > 7 || target[0] < 0 || target[0] > 7 || target[1] < 0 || target[1] > 7
        invalid_move(move, "INVALID MOVE: out of bounds")
        return false
      end
      piece_type = source_square.class
      unless flags[:nocheck]
      #if is_check?
        test_position = new_position_from_move(move)
        test_position.to_play = @to_play
        if test_position.is_check?
          puts "INVALID MOVE: in check"
          return false
        end
      #end
      end

      r = case source_square
      when Chess::Piece::Pawn
        is_pawn_move_legal?(source, target, player)
      when Chess::Piece::Knight
        is_knight_move_legal?(source,target, player)
      when Chess::Piece::Rook
        is_rook_move_legal?(source, target, player)
      when Chess::Piece::Bishop
        is_bishop_move_legal?(source,target, player)
      when Chess::Piece::Queen
        is_queen_move_legal?(source, target, player)
      when Chess::Piece::King
        is_king_move_legal?(source, target, player)
      end
      #puts "source_square = #{source_square.inspect}, r = #{r}"
      r
    end

    def path_clear?(source, target)
      min_rank = [source[0], target[0]].min
      max_rank = [source[0], target[0]].max 
      min_file = [source[1], target[1]].min
      max_file = [source[1], target[1]].max
      if source[0] == target[0]
        # file move
        (min_file + 1).upto(max_file - 1) do |i|
          return false unless @squares[source[0]][i].nil?
        end
      elsif source[1] == target[1]
        # rank move
        (min_rank + 1).upto(max_rank - 1) do |i|
          return false unless @squares[i][source[1]].nil?
        end
      else
        # diagonal move
        distance = (source[0] - target[0]).abs
        if( (source[1] - target[1]).abs != distance)
          return false
        end

        rank_array = (([source[0],target[0]].min)..([source[0],target[0]].max)).to_a
        if target[0] < source[0]
          rank_array.reverse!
        end

        file_array = (([source[1],target[1]].min)..([source[1],target[1]].max)).to_a
        if target[1] < source[1]
          file_array.reverse!
        end
        
        1.upto(distance - 1) do |i|
          r = rank_array[i]
          f = file_array[i]
          return false unless @squares[r][f].nil?
        end

      end
      true
    end

    def is_pawn_move_legal?(source, target, player = nil)
      player ||= @to_play
      if(player == :white)
        if (target[0] == source[0] + 1) && (source[1] == target[1])
          #forward 1
          if @squares[target[0]][target[1]].nil?
            return true
          end
        end
        if(source[0] == 1 && target[0] == 3) && (source[1] == target[1])
          # forward 2 on first move
          if @squares[target[0]][target[1]].nil? && @squares[2][target[1]].nil?
            return true
          end
        end
        if ( (target[0] == source[0] + 1) && ((target[1] == source[1] + 1) || (target[1] == source[1] - 1)))
          #capture
          if !@squares[target[0]][target[1]].nil? && @squares[target[0]][target[1]].color == :black
            return true
          end
          # en passant
          if @en_passant_square == target
            return true
          end
        end
      else
        if (target[0] == source[0] - 1) && (source[1] == target[1])
          #forward 1
          if @squares[target[0]][target[1]].nil?
            return true
          end
        end
        if(source[0] == 6 && target[0] == 4) && (source[1] == target[1])
          # forward 2 on first move
          if @squares[target[0]][target[1]].nil? && @squares[5][target[1]].nil?
            return true
          end
        end
        if ( (target[0] == source[0] - 1) && ((target[1] == source[1] + 1) || (target[1] == source[1] - 1)))
          #capture
          if !@squares[target[0]][target[1]].nil? && @squares[target[0]][target[1]].color == :white
            return true
          end
          # en passant
          if @en_passant_square == target
            return true
          end
        end
      end
      false
    end

    def is_knight_move_legal?(source, target, player = nil)
      #puts "source = #{source.inspect}, target = #{target.inspect}"
      rank_diff = (source[0] - target[0]).abs
      file_diff = (source[1] - target[1]).abs
      if (rank_diff == 1 && file_diff == 2) || (rank_diff == 2 && file_diff == 1)
        true
      else
        false
      end
    end

    def is_rook_move_legal?(source, target, player = nil)
      if source[0] != target[0] && source[1] != target[1]
        return false
      end
      return false unless path_clear?(source, target)
      true
    end
    def is_bishop_move_legal?(source, target, player = nil)
      return false unless path_clear?(source, target)
      unless (source[0] - target[0]).abs == (source[1] - target[1]).abs
        return false
      end
      true
    end
    def is_queen_move_legal?(source, target, player = nil)
      is_rook_move_legal?(source, target) || is_bishop_move_legal?(source,target)
    end

    def is_king_move_legal?(source, target, player = nil)
      player ||= @to_play
      # check castling
      if(player == :white)
        if(source == [0,4] && target == [0,6])
          return can_castle?(:king)
        end
        if(source == [0,4] && target == [0,2])
          return can_castle?(:queen)
        end
      else
        if(source == [7,4] && target == [7,6])
          return can_castle?(:king)
        end
        if(source == [7,4] && target == [7,2])
          return can_castle?(:queen)
        end
      end
      if (source[0] - target[0]).abs > 1 || (source[1] - target[1]).abs > 1
        false
      else
        true
      end
    end

    def is_check?(player = nil)
      #puts "is_check"
      player ||= @to_play
      other_player = player == :white ? :black : :white
      king_square = find_pieces(Chess::Piece::King, @to_play)[0]
      ret = square_attacked?(king_square, other_player) 
      #puts "done is_check #{ret}"
      ret
    end

    def square_attacked?(square, player)
      squares = find_pieces(nil, player)
      squares.each do |sq|
        move = Chess::Move.new(sq, square)
        if is_legal?(move, :player => player, :nocheck => true)
          return true
        end
      end
      false
    end

    def is_checkmate?
      #puts "is_checkmate"
      return false unless is_check?
      if legal_moves.size == 0
        true
      else
        false
      end
    end

    def legal_moves
      piece_squares = find_pieces(nil, @to_play)
      lmoves = []
      piece_squares.each do |sq|
        0.upto(7) do |i|
          0.upto(7) do |j|
            move = Chess::Move.new(sq, [i,j])
            if is_legal?(move)
              lmoves << move
            end
          end
        end
      end
      lmoves
    end

  end

end

