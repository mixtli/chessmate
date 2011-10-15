require 'eventmachine'
Thread.abort_on_exception = true
class Chess::Client::FICS < Chess::Client::Base
  attr_accessor :thread, :callback_object
  RE_NEWLINE = /\r?\n/
  RE_EMPTY = /^[\s\r\n]*$/

  def run
    @thread = Thread.new do
      EventMachine.run do
        @connection = EventMachine.connect @options[:server], @options[:port], FICSConnection, {:username => @options[:username], :password => @options[:password], :log_file => @options[:log_file], :callback_object => @callback_object}
      end
    end
  end

  def log(str)
    if @logfile
      @logfile.puts str
    end
  end
  def command(str, &block)
    EM.next_tick do
      @connection.send_line(str, &block)
    end
  end

  def send_move(move, &blk)
    log "FICS.send_move(#{move.to_s}"
    command(move.to_s) do |id, code, text|
      log("in send_move:command")
      if blk
        log("calling block")
        blk.call(@connection.parse_move(text))
        log("done calling block")
      end
    end
  end

  def sought
    command("sought") do |id, code, text|
      log "got id = #{id}, code = #{code}, text = #{text}"
      seeks = []
      seek_lines = text.split(RE_NEWLINE)
      seek_lines.each do |sline|
        next if sline =~ /ads displayed/
        sl = sline.split(/\s+/) 
        next if sl.empty?
        if sl[8] =~ /white|black/
          color = sl[8].gsub(/[\[|\]]/, '')
          range = sl[9]
          flags = sl[10]
        else
          color = nil
          range = sl[8]
          flags = sl[9]
        end

       seeks << { :id => sl[1], :rating => sl[2], :username => sl[3], :time => sl[4], :increment => sl[5], :rated => sl[6], :type => sl[7], :color => color, :range => range, :flags => flags} 
      end
      callback_object.sought_callback(seeks)
    end
  end

  def match(user, args = {})
    cmd = "match #{user}"
    if args[:rated]
      cmd << " rated"
    else
      cmd << " unrated"
    end
    cmd << " #{args[:time]}" if args[:time]
    cmd << " #{args[:inc]}" if args[:inc]
    cmd << " #{args[:color].to_s}" if args[:color]
    command(cmd)

  end

  def accept
    command("accept")
  end

  def games
    commands("games") do |id, code, text|
      games = []
      game_lines = text.split(RE_NEWLINE)
      game_lines.each do |gline|

      end
    end
  end

end


class FICSConnection < EM::Connection
  RE_LOGIN = /login:/
  RE_PASSWORD = /password:/
  RE_SESSION_START = /Starting FICS session/
  BLOCK_START = 21.chr
  BLOCK_SEPARATOR = 22.chr
  BLOCK_END = 23.chr
  BLOCK_POSE_START = 24.chr 
  BLOCK_POSE_END = 25.chr

  RE_BLOCK_START = /#{BLOCK_START}(\d+)#{BLOCK_SEPARATOR}(\d+)#{BLOCK_SEPARATOR}/
  RE_BLOCK_END = /#{BLOCK_END}/
  RE_EMPTY = /^[\s\r\n]*$/
  PROMPT = "fics%"
  load File.dirname(__FILE__) + "/block_codes.rb"
  
  def initialize(opts = {})
    @username= opts[:username]
    @password = opts[:password]
    @callback_object = opts[:callback_object]
    @deferred_replies = []
    if opts[:log_file]
      @logfile = File.open("#{opts[:log_file]}", "a")
    end
    super
  rescue => e
    puts e.message
    puts e.backtrace
  end

  def debug_data(str)
    str.gsub(BLOCK_START, "<start>").gsub(BLOCK_END, "<end>").gsub(BLOCK_SEPARATOR, "<seperator>")
  end
  def receive_data(data)
    log "receive_data(#{debug_data(data)})"
    (@buf ||= '') << data
    if RE_LOGIN.match(@buf)
      send_line(@username)
      @buf = ''
    end
    if RE_PASSWORD.match(@buf)
      send_line(@password)
      @buf = ''
    end
    while line = @buf.slice!(/(.*)\r?\n/)
      receive_line(line)
    end
  end
  def receive_line(line)
    if line[0,5] == PROMPT
      line = line[6, line.length - 5]
    end
    line.chomp!
    return if line.length == 0
    log "receive_line: [#{debug_data(line)}]"
  
    if RE_SESSION_START.match(line)
      setup_session
    end

    if @in_reply
      n = RE_BLOCK_END.match(line)
      if n
        (id, code, text) = @in_reply
        @in_reply = nil
        handle_reply(id, code, text + "\n" + line[0,n.begin(0)])
      else
        @in_reply[2] = @in_reply[2] + "\n" + line
      end
      return
    end

    if RE_EMPTY.match(line)
      return
    end

    m = RE_BLOCK_START.match(line)
    if m
      id = m[1].to_i
      code = m[2].to_i
      text = line[m.end(0), line.length]
      n = RE_BLOCK_END.match(text)
      if n
        handle_reply(id, code, text[0,n.begin(0)])
      else
        @in_reply = [id, code, text]
      end
      return
    end

    if line[0,4] == "<12>"
      handle_move(line)
    else
      console(line)
    end
  end

  def console(line)
    log("console(#{line})") 
    if @callback_object.respond_to?(:console_callback)
      @callback_object.console_callback(line)
    end
  end

  def log(str)
    if @logfile
      @logfile.puts str
    end
  end

  def handle_reply(id, code, text)
    lines = text.split(/\n/)
    log "handle_reply(#{id}, #{code}, #{BLOCK_DESCRIPTIONS[code]}, #{text})"
    reply_deferred = nil
    pos = id - 2 # 1 is reserved for commands that don't need response
    if pos >= 0
      reply_deferred = @deferred_replies[pos]
      @deferred_replies[pos] = nil
    end
    case code
    when BLK_ACCEPT
      mv = lines.select {|l| l[0,4] == "<12>" }[0]
      lines.delete(mv)
      m = handle_move(mv)
    when BLK_GAME_MOVE
    else
    end
    if reply_deferred
      log "calling reply_deferred"
      reply_deferred.call(id, code, text)
      log "done calling reply_deferred"
    else
      console(text)
    end
  end

  def parse_move(move_str)
    log "parse_move(#{move_str})"
    fields = move_str.split(" ")
    move = {
      :ranks => fields[1..8],
      :turn => fields[9],
      :double_push => fields[10],
      :white_castle_short => fields[11],
      :white_castle_long => fields[12],
      :black_castle_short => fields[13],
      :black_castle_long => fields[14],
      :reversible_moves => fields[15],
      :id => fields[16].to_i,
      :white_player => fields[17],
      :black_player => fields[18],
      :relation => fields[19],
      :time => fields[20],
      :increment => fields[21],
      :white_material => fields[22],
      :black_material => fields[23],
      :white_time => fields[24],
      :black_time => fields[25],
      :move_number => fields[26],
      :move => fields[27],
      :time_taken => fields[28],
      :pretty_move => fields[29],
      :flip_field => fields[30]
    }
    log move.inspect
    move
  end

  def handle_move(move_str)
    move = parse_move(move_str)
    if @callback_object.respond_to?(:move_callback)
      @callback_object.move_callback(move)
    end
  end
  def setup_session
    @logged_in = true
    send_line("iset defprompt 1")
    send_line("iset nowrap 1")
    send_line("set interface iChess")
    send_line("set open 1")
    send_line("set cshout 0")
    send_line("set seek 0")
    send_line("set gin 0")
    send_line("set pin 0")
    send_line("- channel 53")
    send_line("iset block 1")
    @mode = :block
  end




  def send_line(line, &block)
    if block
      id = @deferred_replies.count
      0.upto(@deferred_replies.count) do |i|
        unless @deferred_replies[i]
          id = i
        end
      end

      if @deferred_replies.count == id
        @deferred_replies << block
      else
        @deferred_replies[id] = block
      end

      log "SEND #{id + 2} #{line}"
      # reserve 1 for commands that don't need response
      send_data("#{id + 2} #{line}\n")
    else
      if @mode == :block
        sline = "1 #{line}\n"
      else
        sline = line
      end
      log("SEND: #{sline}")
      send_data(sline + "\n")
    end
  end
  
end

