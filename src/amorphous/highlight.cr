class Amorphous::Highlight
  def initialize(@previous, @start, @end, @style); end

  getter previous, :start, :end, style

  def self.append(previous, start_index, end_index, style)
    while previous && start_index <= previous.start
      previous = previous.previous
    end

    if previous
      if end_index < previous.end
        return previous
      end
      if start_index < previous.end
        previous = new previous.previous, previous.start, start_index, previous.style
      end
    end

    new previous, start_index, end_index, style
  end

  def show(io, line, highlighter)
    if previous = @previous
      previous.show io, line, highlighter
      io << line[previous.end...@start]
    else
      io << line[0...@start]
    end

    highlighter.highlight io, line[@start...@end], @style
  end
end
