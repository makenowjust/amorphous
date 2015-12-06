module Amorphous::Parsers
  module Seq
    extend self

    {% begin %}
      {% types = [] of MacroId %}
      {% parsers = [] of MacroId %}
      {% tparsers = [] of MacroId %}
      {% values = [] of MacroId %}

      {% for i in (1..16) %}
        {% types.push "T#{i}".id %}
        {% parsers.push "parser#{i}".id %}
        {% tparsers.push "parser#{i} : Parser(T#{i})".id %}
        {% values.push "val#{i}".id %}

        @[AlwaysInline]
        def seq({{ *tparsers }})
          Parser({ {{ *types }} }).new do |src|
            {% for value, i in values %}
              {{ value }} :: {{ types[i] }}
            {% end %}

            {% for parser, i in parsers %}
              case res = {{ parser }}.run src
              when Success
                {{ values[i] }} = res.value
                src = res.source
              else
                return res
              end
            {% end %}
            Success.new src, { {{ *values }} }
          end
        end

        @[AlwaysInline]
        def seq({{ *tparsers }}, &block : {{ *types }} -> S)
          Parser(S).new do |src|
            {% for value, i in values %}
              {{ value }} :: {{ types[i] }}
            {% end %}

            {% for parser, i in parsers %}
              case res = {{ parser }}.run src
              when Success
                {{ values[i] }} = res.value
                src = res.source
              else
                return res
              end
            {% end %}
            Success.new src, block.call {{ *values }}
          end
        end
      {% end %}
    {% end %}
  end

  include Seq
end
