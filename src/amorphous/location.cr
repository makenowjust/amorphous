module Amorphous
  record Location, position, row, column do
    include Comparable(self)

    def next(char)
      if char == '\n'
        self.class.new position + 1, row + 1, 1
      else
        self.class.new position + 1, row, column + 1
      end
    end

    def <=>(other : self)
      position <=> other.position
    end

    def to_s(io)
      io << "#{row}:#{column}"
    end
  end
end
