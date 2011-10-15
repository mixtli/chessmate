require "chess/player"
require "chess/move"

class Chess::Game
  attr_accessor :move_list, :result, :players, :event, :site, :date, :round, :to_play, :position, :increment,  :start_time, :wtime, :btime, :callback_object, :winc, :binc, :white_player, :black_player, :initial_position, :tags, :comment, :current_move, :first_move, :type, :id

  def initialize
    @move_list = []
    @result = nil
    @players = {
      :white => Chess::Player.new('White'),
      :black => Chess::Player.new('Black')
    }

    @to_play = :white
    @position = @initial_position = Chess::Position.initial
    @tags = {}
  end

  def set_player(color, player)
    self.players.setValue(player, forKey: color)
    #self.players[color.to_s] = player
  end
  
  def white_player
    self.players[:white]
  end

  def black_player
    self.players[:black]
  end

  def self.from_pgn(pgn_txt)
    #puts "----------------------------"
    #puts pgn_txt
    parser = PGNParser.new
    result = parser.parse(pgn_txt, :root => :game)
    unless result
      puts "REASON: " + parser.failure_reason
      puts "LINE: " + parser.failure_line.to_s
      puts "COLUMN: " + parser.failure_column.to_s
      puts "INDEX: " + parser.index.to_s
      puts "FAILURE INDEX: " + parser.failure_index.to_s
      puts "failure character = [#{pgn_txt[parser.failure_index]}]"
      puts pgn_txt[(parser.failure_index-5)..(parser.failure_index+5)]
      raise "Failed to import game"
    end

    #puts result.inspect
    game = new
    if result.comment.text_value.length > 0
      game.comment = result.comment.text_value.gsub(/\r?\n/,' ')
    end
    game.tags = {}

    result.tag_section.elements.each do |tag_section|
      k = tag_section.tag_name.text_value
      v = tag_section.tag_value.tval.text_value
      game.tags[k] = v
    end

    game.event = game.tags.delete('Event')
    game.players[:white] = Chess::Player.new(game.tags.delete('White'))
    game.players[:black] = Chess::Player.new(game.tags.delete('Black'))
    game.site = game.tags.delete('Site')
    game.date = game.tags.delete('Date')
    game.round = game.tags['Round'] == '?' ? nil : game.tags['Round'].to_i
    game.tags.delete('Round')
    game.result = game.tags.delete('Result')

    if game.tags['FEN']
      puts "got fen"
      game.position = game.initial_position = Chess::Position.from_fen(game.tags['FEN'])
    end

    puts game.position.to_fen
    game.first_move = parse_move_list(result.movetext_section.moves, game.initial_position )
    game
  end

  def self.parse_move_list(parsed_moves, position,  parent_move = nil)
    if parent_move
      previous_move = parent_move.previous
    end
    first_move = nil
    parsed_moves.each do |move_node|
      mv = move_node.san_move.text_value
      move = position.create_move(mv)
      first_move ||= move
      if move_node.comment.text_value.length > 0
        move.annotation = move_node.comment.text_value.gsub(/\r?\n/, ' ')
      end
      move.numeric_annotations = move_node.numeric_annotations
      previous_move.next = move if previous_move && !previous_move.next
      move.previous = previous_move
      previous_move = move
      previous_position = position
      position = position.new_position_from_move(move)
      #mv_list << move
      move_node.variations.each do |var|
        #variation = []
        variation = parse_move_list(var.moves, previous_position, move)
        move.variation_moves << variation
      end
    end
    first_move
  end

  def move_list
    #return @move_list if @move_list
    return [] unless self.first_move
    mv = self.first_move
    @move_list = [mv]
    while(mv = mv.next)
      @move_list << mv
    end
    @move_list
  end

  def get_position(move)
    return self.initial_position unless move
    #return move.position if move.position
    initial_move = move
    mv_list = [move]
    while(move = move.previous)
      mv_list.unshift(move)
    end
    #puts "got mv_list = #{mv_list.inspect}"
    pos = self.initial_position 
    while(mv = mv_list.shift)
      pos = pos.new_position_from_move(mv)
    end
    initial_move.position = pos
    pos
  end

  def self.load_pgn(file_name)
    failure_count = total_count = 0
    games = []
    texts = []
    text = ''
    file = File.new(file_name)
    in_move_text = false
    while line = file.gets
      #puts "in_move_text = #{in_move_text}"
      #puts line
      if line =~ /^\r?\n$/
        #puts "got newline"
        if in_move_text
          texts << text
          text = ''
          in_move_text = false
        end
      end
      if line[0] == '['
        in_move_text = false
      else
        in_move_text = true
      end
      text << line
    end
    if text.length > 1
      texts << text
    end
    texts.each do |txt|  
      #puts "parsing txt"
      #puts txt
      total_count += 1
      txt.sub!(/^[\s\n\r]*/, '')
      begin
      games << from_pgn(txt)
      rescue => e
        puts "----------------------------"
        puts txt
        puts e.message
        failure_count += 1
        raise "done"
      end
    end
    puts "#{failure_count} games failed to import out of #{total_count}"
    games
  end

  def make_move(move_arg)
    move = move_arg.kind_of?(String) ? current_position.create_move(move_arg) : move_arg
    #puts move.inspect
    #puts "position move num = #{position.move_number}"
    #puts "move number = #{move.number}"
    move.previous = self.current_move
    if move.previous && !move.previous.next
      move.previous.next = move
    end
    self.current_move = move
    unless self.first_move
      self.first_move = self.current_move
    end
    #puts "first_move = #{self.first_move.inspect}, current_move = #{self.current_move.inspect}"
    #self.position = @position.new_position_from_move(move)
    #@move_list << move
    #self.to_play = self.position.to_play 
    #self.position
  end

  def to_play
    if self.current_move && self.current_move.player == :white
      :black
    else
      :white
    end
  end

  def current_position
    get_position(self.current_move)
  end

  def position
    current_position
  end

  def add_variation(parent, move)
    position = get_position(parent.previous)
    move.previous = parent.previous
    parent.variation_moves << move
    self.position = position.new_position_from_move(move)
    #self.position
  end

  def last_move_number
    (move_list.length - 1)/2 + 1
  end

  def get_move(number, player)
    idx = (number - 1) * 2
    if player == :black
      idx += 1
    end
    move_list[idx]
  end


  def to_pgn
    pgn = <<-EOS
[Event "#{event || "?"}"]
[Site "#{site || "?"}"]
[Date "#{date || "????.??.??"}"]
[Round "#{round || "?"}"]
[White "#{players[:white] || "?"}"]
[Black "#{players[:black] || "?"}"]
[Result "#{result || "?"}"]
    EOS
    puts @tags.keys.sort.inspect
    @tags.keys.sort.each do |k|
      pgn << "[#{k} \"#{@tags[k]}\"]\n"
    end

    pgn << "\n"
    if @comment
      pgn << "{#{@comment}}"
    end
      
    pgn << full_move_string
    pgn << " #{result}\n"
    pgn
  end

  def move_list_string
    str = ''
    @move_list.each_with_index do |move, i|
      if i%2 == 0
        str << "#{i/2 + 1}."
      end
      str << " #{move}" 
    end
    str
  end

  def full_move_string
    str = ''
    move_list.each_with_index do |move, i|
      str << "#{move.full_string} "
    end
    str
  end
  def wrap_long_string(text,max_width = 80)
    (text.length < max_width) ?
      text :
      text.scan(/.{1,#{max_width}}/).join("\n")
  end
  
end

