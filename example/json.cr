require "colorize"

require "../src/amorphous"

class Highlighter
  STYLE = {
    error:    {:white, :red, :bold},
    punctual: {:white,  nil, :bold},
    literal:  {:red  ,  nil, :bold},
    string:   {:green,  nil,  nil},
    keyword:  {:cyan ,  nil,  nil},
  }

  def highlight(io, str, style)
    if style && (s = STYLE[style]?)
      str = str.colorize
      str = str.fore(s[0].not_nil!) if s[0]
      str = str.back(s[1].not_nil!) if s[1]
      str = str.mode(s[2].not_nil!) if s[2]
    end
    io << str
  end
end

module JSONParser
  alias Result = Nil | Bool | String | Float64 | Array(Result) | Hash(String, Result)


  extend self

  include Amorphous
  include Amorphous::Parsers


  VALUE = Parser(Result).lazy


  # RFC 7159
  # https://tools.ietf.org/html/rfc7159

  # 2. JSON Grammer

  WS = (char(' ') | char('\t') | char('\n') | char('\r')).skip_many

  JSON = WS >> VALUE << WS << eof

  BEGIN_ARRAY = WS >> char('[').highlight(:punctual) << WS
  BEGIN_OBJECT = WS >> char('{').highlight(:punctual) << WS
  END_ARRAY = WS >> char(']').highlight(:punctual) << WS
  END_OBJECT = WS >> char('}').highlight(:punctual) << WS

  NAME_SEPARATOR = WS >> char(':').highlight(:punctual) << WS
  VALUE_SEPARATOR = WS >> char(',').highlight(:punctual) << WS


  # 6. Number

  DIGIT = range('0'..'9')
  DIGIT1_9 = range('1'..'9')
  E = char('e') | char('E')
  MINUS = char('-')
  PLUS = char('+')
  EXP = seq(E, (MINUS | PLUS).opt, DIGIT.some) do |e, op, num|
    "#{e}#{op}#{num}"
  end
  FRAC = seq(char('.'), DIGIT.some) do |pt, num|
    "#{pt}#{num}"
  end
  INT = char('0').map(&.to_s) | seq(DIGIT1_9, DIGIT.many.map(&.join)){ |c, s| "#{c}#{s}" }

  NUMBER = seq(MINUS.opt, INT, FRAC.opt, EXP.opt) do |op, i, f, e|
    "#{op}#{i}#{f}#{e}".to_f as Result
  end.highlight(:literal).name("number")


  # 7. Strings

  HEXDIG = DIGIT | range('a'..'f') | range('A'..'F')
  UNESCAPED = range('\u{20}'..'\u{21}') | range('\u{23}'..'\u{5B}') | range('\u{5D}'..'\u{10FFFF}')
  CHAR = UNESCAPED | (char('\\') >> (
    char('"')  |
    char('\\') |
    char('/')  |
    char('b').map{ '\b' } |
    char('f').map{ '\f' } |
    char('n').map{ '\n' } |
    char('r').map{ '\r' } |
    char('t').map{ '\t' } |
    char('u') >> HEXDIG.count(4).map{ |s| s.join.to_i(16).chr } |
    fail(Char, "Invalid escape sequence"))) |
    fail(Char, "Invalid character")
  STRING = (char('"') >> CHAR.many.map(&.join) << char('"'))
    .highlight(:string).name("string")


  # 4. Objects

  MEMBER = seq(STRING << NAME_SEPARATOR, VALUE)
  OBJECT = (BEGIN_OBJECT >> MEMBER.sep_by(VALUE_SEPARATOR) << END_OBJECT)
    .map do |object|
      Hash(String, Result).new.tap do |result|
        object.each do |name_and_value|
          name, value = name_and_value
          result[name] = value
        end
      end as Result
    end


  # 5. Arrays

  ARRAY = BEGIN_ARRAY >> VALUE.sep_by(VALUE_SEPARATOR).map{ |a| a as Result } << END_ARRAY


  # 3. Values

  TRUE = string("true").map{ true as Result }.highlight(:keyword).name("true")
  FALSE = string("false").map{ false as Result }.highlight(:keyword).name("false")
  NULL = string("null").map{ nil as Result }.highlight(:keyword).name("null")

  VALUE.bind = TRUE | FALSE | NULL | OBJECT | ARRAY | NUMBER | STRING.map{ |s| s as Result }


  def run(source : String)
    JSONParser.run(Source.new MemoryIO.new(source), "<source>")
  end

  def run(source)
    JSON.run source
  end
end

def test(source)
  puts "Source: #{source.inspect}"
  case res = JSONParser.run source
  when Amorphous::Success
    puts "Result: #{res.value.inspect}"
  else
    print "Failure: "
    res.to_s STDOUT, Highlighter.new
  end
  puts "---"
end

test %({})
test %("\\uGGGG")
test %({"hello": "world"})
test %({"ok": "\\google"})
test %({"hey": "siri",})
