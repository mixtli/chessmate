require 'citrus'
#require 'citrus/debug'

Citrus.load 'pgn_parser'

txt = '8...'

#r = PGNParser.parse(txt, :root => :move_number_indication)
#puts r.inspect
#exit;

txt = '[Event "F/S Return Match"]
[Site "Belgrade, Serbia Yugoslavia|JUG"]
[Date "1992.11.04"]
[Round "29"]
[White "Fischer, Robert J."]
[Black "Spassky, Boris V."]
[Result "1/2-1/2"]
'

tag_section_txt = 
'[Event "Crakow"]
[Site "Crakow"]
[Date "1942.??.??"]
[Round "?"]
[White "Alekhine"]
[Black "Junge"]
[Result "1-0"]
[ECO "C86"]
[Annotator "01: Active Bishop"]
[PlyCount "57"]
[Source "Hays Publishing"]
[SourceDate "1964.01.01"]
'

move_txt = '1. e4 e5 2. f3 f5 3. f3 g3 4. a5 1-0
'
move_txt = '1. a4 a5 2. g3 a4 1-0
'

game_txt = "#{tag_section_txt}\n#{move_txt}\n"
puts "|#{game_txt}|"



txt = File.read("test3.pgn")
puts "|#{txt}|"

puts game_txt.length

puts txt.length

headers, move_text = txt.split(/\r?\n\r?\n/)
puts "headers = #{headers}"
puts "move_text = #{move_text}"
move_text.gsub!(/\r?\n/, " ")
move_text[move_text.length - 1] = "\n"
txt = headers + "\n\n" +  move_text 

puts "|#{txt}|"
begin 
  #r = PGNParser.parse(game_txt, :root => :game)
  r = PGNParser.parse(txt, :root => :game)
rescue => e
  puts e.inspect
  puts "yo"
  puts e.line
  puts e.line[(e.line_offset-2)..(e.line.length)]
end

puts "r = #{r.dump}"

puts r.captures[:game].count

r.captures[:game].each do |game|
  game.captures[:tag_section].each do |section|
    section.captures[:tag_pair].each do |pair|
      puts pair.captures[:tag_name]
      puts pair.captures[:tag_value].first.value
    end
  end
  game.captures[:movetext_section].each do |move_list|
    move_list.captures[:move_sequence].each do |sequence|
      puts sequence.inspect
      puts sequence.captures[:move].count
      move = sequence.captures[:move].first
      sequence.captures[:move].each do |move|
       puts move.inspect
      end
    end
  end
end

