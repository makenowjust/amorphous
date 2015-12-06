require "./highlight"
require "./location"

class Amorphous::Source
  # Create a new source from *io*.
  def self.new(io, filename = io.inspect, loc = Location.new(0, 1, 1))
    line = io.gets
    new io, filename, line || "", 0, line.nil?, loc, nil
  end

  # :nodoc:
  def initialize(
    @io,
    @filename,
    @line, @line_index,
    @eof,
    @location,
    @highlight); end

  # Returns the file name of this source.
  getter filename

  # Returns current location.
  getter location

  # :nodoc:
  protected def line; @line end
  # :nodoc:
  protected def line_index; @line_index end

  # Returns current charcter or nil. nil means EOF.
  def current_char
    if @eof
      return nil
    end

    @line[@line_index]
  end

  # Returns next source.
  def next
    if next_source = @next
      return next_source
    end

    if @eof
      raise "EOF has no next source"
    else
      location = @location.next current_char

      line = @line
      line_index = @line_index + 1
      highlight = @highlight
      eof = false

      unless line_index < @line.size
        if next_line = @io.gets
          line = next_line
          line_index = 0
          highlight = nil
        else
          eof = true
        end
      end

      @next ||= Source.new @io, @filename, line, line_index, eof, location, highlight
    end
  end

  def consume(start, style = nil)
    if location < start.location
      raise "Invalid consume location #{start.location}"
    end

    start_index = start.line_index
    unless start.line.same? @line
      start_index = 0
    end

    Source.new @io, @filename, @line, @line_index, @eof, @location, Highlight.append(@highlight, start_index, line_index, style)
  end

  def to_s(io, highlighter = Amorphous.default_highlighter)
    if highlight = @highlight
      highlight.show io, @line.gsub('\n', ' '), highlighter
      io.puts @line[highlight.end..-1]
    else
      io.puts @line
    end
  end
end
