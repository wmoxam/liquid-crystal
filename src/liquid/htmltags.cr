module Liquid
  class TableRow < Block
    include Liquid::Data
    Syntax = /(\w+)\s+in\s+(#{QuotedFragment}+)/

    @variable_name : String
    @collection_name : String

    def initialize(tag_name, markup, tokens)
      if markup =~ Syntax
        @variable_name = $1
        @collection_name = $2
        @attributes = {} of String => Type
        markup.scan(TagAttributes) do |match|
          @attributes[match[1].not_nil!] = match[2]?
        end
      else
        raise SyntaxError.new("Syntax Error in 'table_row loop' - Valid " \
          "syntax: table_row [item] in [collection] cols=3")
      end

      super
    end

    def render(context)
      collection = context[@collection_name]
      return "" if collection.nil?

      from = if @attributes["offset"]?
        Any.new(context[@attributes["offset"]]).to_i
      else
        0
      end

      to = if @attributes["limit"]?
        from + Any.new(context[@attributes["limit"]]).to_i
      else
        nil
      end

      collection = Utils.slice_collection_using_each(
        Any.new(collection),
        from,
        to)

      length = collection.size

      cols = Any.new(context[@attributes["cols"]?]).to_i

      row = 1
      col = 0

      String.build do |result|
        result << "<tr class=\"row1\">\n"
        context.stack do

          collection.each_with_index do |item, index|
            context[@variable_name] = item
            context["tablerowloop"] = _h({
              "length"  => length,
              "index"   => index + 1,
              "index0"  => index,
              "col"     => col + 1,
              "col0"    => col,
              "index0"  => index,
              "rindex"  => length - index,
              "rindex0" => length - index - 1,
              "first"   => (index == 0),
              "last"    => (index == length - 1),
              "col_first" => (col == 0),
              "col_last"  => (col == cols - 1)
            })


            col += 1

            result << "<td class=\"col#{col}\">"
            result << render_all(@nodelist, context)
            result << "</td>"

            if col == cols && !(index == length - 1)
              col  = 0
              row += 1
              result << "</tr>\n<tr class=\"row#{row}\">"
            end

          end
        end
        result << "</tr>\n"
      end
    end
  end

  Template.register_tag("tablerow", TableRow)
end
