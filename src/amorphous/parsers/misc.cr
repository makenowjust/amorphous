require "../parser"
require "../result"

class Amorphous::Parser(T)
  @[AlwaysInline]
  def highlight(style)
    Parser(T).new do |src|
      start = src
      case res = run src
      when Success
        res.update res.source.consume start, style
      else
        res
      end
    end
  end

  @[AlwaysInline]
  def name(name)
    Parser(T).new do |src|
      case res = run src
      when Success
        res
      else
        if src.location == res.source.location
          Expected.new res.source, name
        else
          res
        end
      end
    end
  end

  @[AlwaysInline]
  def self.lazy
    Lazy(T).new
  end

  class Lazy(T) < Parser(T)
    def initialize
      super do |src|
        bind.run src
      end
    end

    property! bind
  end
end
