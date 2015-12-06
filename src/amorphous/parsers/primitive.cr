module Amorphous::Parsers
  module Primitive
    extend self

    @[AlwaysInline]
    def location
      Parser(Location).new do |src|
        Success.new src, src.location
      end
    end

    @[AlwaysInline]
    def fail(t : T, message)
      Parser(T).new do |src|
        Failure.new src, message
      end
    end

    @[AlwaysInline]
    def any
      Parser(Char).new do |src|
        Success.new src.next, src.current_char
      end
    end

    @[AlwaysInline]
    def eof
      Parser(Nil).new do |src|
        if src.current_char
          Expected.new src, "EOF"
        else
          Success.new src, nil
        end
      end
    end

    @[AlwaysInline]
    def char(c)
      Parser(Char).new do |src|
        if src.current_char == c
          Success.new src.next, c
        else
          Expected.new src, c.inspect
        end
      end
    end

    @[AlwaysInline]
    def range(r)
      Parser(Char).new do |src|
        if (c = src.current_char) && r.covers? c
          Success.new src.next, c
        else
          Expected.new src, r.inspect
        end
      end
    end

    @[AlwaysInline]
    def satisfy(&block : Char -> Bool)
      Parser(Char).new do |src|
        c = src.current_char
        if block.call c
          Success.new src.next, c
        else
          Expected.new src
        end
      end
    end

    @[AlwaysInline]
    def string(s)
      Parser(String).new do |src|
        start_src = src
        s.each_char do |c|
          if src.current_char == c
            src = src.next
          else
            return Expected.new start_src, s.inspect
          end
        end
        Success.new src, s
      end
    end
  end

  include Primitive
end
