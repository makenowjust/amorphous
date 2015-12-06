require "./result"
require "./source"

module Amorphous
  class Parser(T)
    @[AlwaysInline]
    def initialize(&@run : Source -> Success(T) | Failure); end

    @[AlwaysInline]
    def run(source)
      @run.call source
    end

    # Define other methods (combinators) in parsers.cr
  end
end
