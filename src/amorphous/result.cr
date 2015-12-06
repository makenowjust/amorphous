require "./source"

module Amorphous
  class Success(T)
    def initialize(@source, @value : T); end

    getter source, value

    def update(source)
      Success.new source, @value
    end
  end

  class Failure
    def initialize(@source, @message = nil); end

    getter source, message

    def to_s(io, highlighter = Amorphous.default_highlighter)
      io.puts "#{@source.filename} (#{@source.location}):"
      io.puts "  #{message}"
      io.puts ""
      source = @source
      if source.current_char
        source = source.next.consume source, :error
      end
      source.to_s io, highlighter
    end

    def self.merge(left, right)
      lloc = left.source.location
      rloc = right.source.location

      case
      when lloc < rloc
        right
      when lloc > rloc
        left
      else
        if left.is_a?(Expected) && right.is_a?(Expected)
          Expected.new right.source, left.expected | right.expected
        else
          if right.is_a?(Expected)
            left
          else
            right
          end
        end
      end
    end
  end

  class Expected < Failure
    def initialize(source, @expected : Set)
      super source
    end

    def initialize(source, *expected)
      super source

      @expected = Set.new expected
    end

    getter expected

    def message
      if @expected.empty?
        "Unexpected #{@source.current_char.try(&.inspect) || "EOF"}"
      else
        "Expceted #{@expected.to_a.join ", "}, but found #{@source.current_char.try(&.inspect) || "EOF"}"
      end
    end
  end
end
