require "../parser"
require "../result"

class Amorphous::Parser(T)
  @[AlwaysInline]
  def map(&block : T -> S)
    Parser(S).new do |src|
      case res = run src
      when Success
        Success.new res.source, block.call res.value
      else
        res
      end
    end
  end

  @[AlwaysInline]
  def bind(&block : T -> Parser(S))
    Parser(S).new do |src|
      case res = run src
      when Success
        block.call(res.value).run res.source
      else
        res
      end
    end
  end

  @[AlwaysInline]
  def <<(rhs)
    Parser(T).new do |src|
      case res1 = run src
      when Success
        case res2 = rhs.run res1.source
        when Success
          res1.update res2.source
        else
          res2
        end
      else
        res1
      end
    end
  end

  @[AlwaysInline]
  def >>(rhs : Parser(S))
    Parser(S).new do |src|
      case res = run src
      when Success
        rhs.run res.source
      else
        res
      end
    end
  end

  @[AlwaysInline]
  def |(rhs : Parser(S))
    Parser(T | S).new do |src|
      case res1 = run src
      when Success
        Success.new res1.source, res1.value as (T | S)
      else
        if src.location == res1.source.location
          case res2 = rhs.run src
          when Success
            Success.new res2.source, res2.value as (T | S)
          else
            Failure.merge res1, res2
          end
        else
          res1
        end
      end
    end
  end

  @[AlwaysInline]
  def count(n)
    Parser(Array(T)).new do |src|
      value = Array(T).new
      n.times do
        case res = run src
        when Success
          value.push res.value
          src = res.source
        else
          return res
        end
      end
      Success.new src, value
    end
  end

  @[AlwaysInline]
  def many
    Parser(Array(T)).new do |src|
      value = Array(T).new
      loop do
        case res = run src
        when Success
          value.push res.value
          src = res.source
        else
          if src.location == res.source.location
            return Success.new src, value
          else
            return res
          end
        end
      end
    end
  end

  @[AlwaysInline]
  def skip_many
    Parser(Nil).new do |src|
      loop do
        case res = run src
        when Success
          src = res.source
        else
          if src.location == res.source.location
            return Success.new src, nil
          else
            return res
          end
        end
      end
    end
  end

  @[AlwaysInline]
  def some
    Parser(Array(T)).new do |src|
      case res = run src
      when Success
        value = [res.value]
        src = res.source
        loop do
          case res = run src
          when Success
            value.push res.value
            src = res.source
          else
            if src.location == res.source.location
              return Success.new src, value
            else
              return res
            end
          end
        end
      else
        res
      end
    end
  end

  @[AlwaysInline]
  def skip_some
    Parser(Nil).new do |src|
      case res = run src
      when Success
        src = res.source
        loop do
          case res = run src
          when Success
            src = res.source
          else
            if src.location == res.source.location
              return Success.new src, value
            else
              return res
            end
          end
        end
      else
        res
      end
    end
  end

  @[AlwaysInline]
  def opt
    Parser(T?).new do |src|
      case res = run src
      when Success
        Success(T?).new res.source, res.value
      else
        if src.location == res.source.location
          return Success.new src, nil
        else
          return res
        end
      end
    end
  end

  @[AlwaysInline]
  def opt(value : S)
    Parser(T | S).new do |src|
      case res = run src
      when Success
        Success(T | S).new res.source, res.value
      else
        if src.location == res.source.location
          return Success.new src, value
        else
          return res
        end
      end
    end
  end

  @[AlwaysInline]
  def opt(&block : -> S)
    Parser(T | S).new do |src|
      case res = run src
      when Success
        Success(T | S).new res.source, res.value
      else
        if src.location == res.source.location
          return Success.new src, block.call
        else
          return res
        end
      end
    end
  end

  @[AlwaysInline]
  def sep_by(sep)
    Parsers.seq(self, (sep >> self).many) do |h, t|
      t.unshift h
      t
    end.opt Array(T).new
  end
end
