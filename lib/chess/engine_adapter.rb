Thread.abort_on_exception = true
class Chess::EngineAdapter
  attr_accessor :executable, :io, :input_thread, :readyok, :move, :callback_object, :options, :position

  def initialize
    @options = {}
    @readyok = false
  end

  def run
    @io = IO.popen(executable, "r+")
    uci
    @input_thread = Thread.new do
      while(line = @io.gets)
        puts "IN:  #{line}"
        process_input(line)
        @io.flush
      end
    end
  end

  def message(msg)
    puts "OUT: #{msg}"
    @io.puts(msg)  
    @io.flush
  end


  def process_input(line)
    tokens = line.split(/\s+/)
    cmd = tokens.shift  
    case cmd
    when 'id'
      process_id(tokens)
    when 'uciok'
      process_uciok
    when 'readyok'
      process_readyok
    when 'bestmove'
      process_bestmove(tokens)
    when 'copyprotection'
      process_copyprotection(tokens)
    when 'registration'
      process_registration(tokens)
    when 'info'
      process_info(tokens)
    when 'option'
      process_option(tokens)
    else
      raise "unknown input #{line}"
    end
  end
  def process_id(args)
    type = args.shift
    if type == 'name'
      @name = args.join(" ")
    else
      @author = args.join(" ")
    end
  end
  def process_uciok
    @uciok = true
  end
  def process_readyok
    @readyok = true
  end
  def process_bestmove(args)
    mv = args.shift
    if args[0] == 'ponder'
      @ponder = args[1]
    else
      @ponder = nil
    end

    @move = parse_move(mv)
    if callback_object
      if callback_object.respond_to?(:bestmove_callback)
        callback_object.bestmove_callback(@move)
      end
    end
  end
  def parse_move(mv)
    source = []
    target = []
    source[0] = mv[1].to_i - 1
    source[1] = mv[0].ord - 97
    target[0] = mv[3].to_i - 1
    target[1] = mv[2].ord - 97
    move = @position.build_move(source, target)
    #move.description = mv
    if mv[4]
      move.promotion = case mv[4]
                       when 'q'
                         Chess::Piece::Queen
                       when 'r'
                         Chess::Piece::Rook
                       when 'b'
                         Chess::Piece::Bishop
                       when 'n'
                         Chess::Piece::Knight
                       end
    end
    move
  end
  def process_copyprotection(args)
    @copyprotection = args[0]
  end
  def process_registration(args)
    @registration = args[0]
  end
  def process_info(args)
  end
  def process_option(args)
    str = args.join(' ')
    matches = /name\s+([\w\s]+)\s+type\s+(\w+)\s+/.match(str)
    name = matches[1]
    type = matches[2]
    @options[name] = {:name => name, :type =>type } 
    
    def_match = /default\s+(.+?)(\s(var|min|max)\s.*)?$/.match(str)
    default_str = def_match[1]
    @options[name][:default] = case type
    when 'check'
      default_str == "true" ? true : false
    else
      default_str
    end
    m =  /min\s+(\w+)/.match(str)
    if(m)
      @options[matches[1]][:min] = m[1].to_i
    end
    m = /max\s+(\w+)/.match(str) 
    if(m)
      @options[matches[1]][:max] = m[1].to_i
    end
    vars  = str.split(/\s+var\s/)
    vars.unshift
    @options[name][:vars] = vars

  end

  def debug(val)
    if val
      message("debug on")
    else 
      message("debug off")
    end
  end

  def uci
    message("uci")
  end

  def isready
    message("isready")
  end

  def setoption(key, value = nil)
    cmd = "setoption name #{key}"
    if value
      cmd << " value #{value}"
    end
    message(cmd)
  end
  
  def register(name = nil, code = nil)
    if name
      message("register name #{name} code #{code}")
    else
      message("register later")
    end
  end

  def ucinewgame
    message("ucinewgame")
  end

  def set_position(pos)
    @position = pos
    position(pos.to_fen)
  end
  def position(pos = nil, moves = nil)
    str = "position "
    if pos
      str << "fen #{pos}"
    else
      str << "startpos"
    end
    if moves
      str << " #{moves}"
    end
    message(str)
  end

  def go(options = {})
    str = "go "
    if options[:ponder]
      str << "ponder "
    end
    if options[:searchmoves]
      str << "searchmoves #{options[:searchmoves].join(' ')} "
    end
    if options[:wtime]
      str << "wtime #{options[:wtime]} "
    end
    if options[:btime]
      str << "btime #{options[:btime]} "
    end
    if options[:winc]
      str << "winc #{options[:winc]} "
    end
    if options[:binc]
      str << "binc #{options[:binc]} "
    end
    if options[:movestogo]
      str << "movestogo #{options[:movestogo]} "
    end
    if options[:depth]
      str << "depth #{options[:depth]} "
    end
    if options[:nodes]
      str << "nodes #{options[:nodes]} "
    end
    if options[:mate]
      str << "mate #{options[:mate]} "
    end
    if options[:movetime]
      str << "movetime #{options[:movetime]} "
    end
    if options[:infinite]
      str << "infinite "
    end
    message(str)
  end

  def stop
    message("stop")
  end

  def ponderhit
    message("ponderhit")
  end
  def quit
    message("quit")
  end

  def kill
    @input_thread.kill
    Process.kill("TERM", @io.pid)
  end

end

