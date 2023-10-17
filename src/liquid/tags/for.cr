module Liquid
  # "For" iterates over an array or collection.
  # Several useful variables are available to you within the loop.
  #
  # == Basic usage:
  #    {% for item in collection %}
  #      {{ forloop.index }}: {{ item.name }}
  #    {% endfor %}
  #
  # == Advanced usage:
  #    {% for item in collection %}
  #      <div {% if forloop.first %}class="first"{% endif %}>
  #        Item {{ forloop.index }}: {{ item.name }}
  #      </div>
  #    {% else %}
  #      There is nothing in the collection.
  #    {% endfor %}
  #
  # You can also define a limit and offset much like SQL.  Remember
  # that offset starts at 0 for the first item.
  #
  #    {% for item in collection limit:5 offset:10 %}
  #      {{ item.name }}
  #    {% end %}
  #
  #  To reverse the for loop simply use {% for item in collection reversed %}
  #
  # == Available variables:
  #
  # forloop.name:: 'item-collection'
  # forloop.length:: Length of the loop
  # forloop.index:: The current item's position in the collection;
  #                 forloop.index starts at 1.
  #                 This is helpful for non-programmers who start believe
  #                 the first item in an array is 1, not 0.
  # forloop.index0:: The current item's position in the collection
  #                  where the first item is 0
  # forloop.rindex:: Number of items remaining in the loop
  #                  (length - index) where 1 is the last item.
  # forloop.rindex0:: Number of items remaining in the loop
  #                   where 0 is the last item.
  # forloop.first:: Returns true if the item is the first item.
  # forloop.last:: Returns true if the item is the last item.
  #
  class For < Block
    Syntax = /(\w+)\s+in\s+(#{QuotedFragment}+)\s*(reversed)?/

    @variable_name : String
    @collection_name : String
    @reversed : String | Nil

    def initialize(tag_name, markup, tokens)
      if markup =~ Syntax
        @variable_name = $1
        @collection_name = $2
        @name = "#{$1}-#{$2}"
        @reversed = $3?
        @attributes = {} of String => String
        markup.scan(TagAttributes) do |capture|
          @attributes[capture[1]] = capture[2]
        end
      else
        raise SyntaxError.new("Syntax Error in 'for loop' - Valid syntax: " \
                              "for [item] in [collection]")
      end

      @nodelist = @for_block = [] of Liquid::Tag | Liquid::Variable | String
      @tag_name = tag_name
      @markup = markup
      parse(tokens)
    end

    def unknown_tag(tag, markup, tokens)
      return super unless tag == "else"
      @for_block = @nodelist.dup
      @nodelist = @else_block = [] of Liquid::Tag | Liquid::Variable | String
    end

    def render(context)
      for_hash = {} of String => Type

      if context.registers.has_key?(:for)
        if (hash = context.registers[:for].raw).is_a?(Hash)
          for_hash = hash
        end
      end

      collection = Any.new(context[@collection_name])

      # Maintains Ruby 1.8.7 String#each behaviour
      return render_else(context) unless collection.iterable?

      from = if @attributes["offset"]? == "continue"
               if for_hash[@name]?.nil?
                 0
               else
                 Any.new(for_hash[@name]).to_i
               end
             elsif @attributes["offset"]?.nil?
               0
             else
               Any.new(context[@attributes["offset"]?]).to_i
             end

      to = if @attributes["limit"]?
             Any.new(context[@attributes["limit"]?]).to_i + from
           else
             nil
           end

      segment = Utils.slice_collection_using_each(collection, from, to)

      return render_else(context) if segment.empty?

      segment = segment.reverse if !@reversed.nil?
      String.build do |result|
        length = segment.size

        # Store our progress through the collection for the continue flag
        for_hash[@name] = (from + segment.size).as(Type)

        context.registers[:for] = for_hash

        context.stack do
          segment.each_with_index do |item, index|
            context[@variable_name] = item
            context["forloop"] = Data.prepare({
              "name"    => @name,
              "length"  => length,
              "index"   => index + 1,
              "index0"  => index,
              "rindex"  => length - index,
              "rindex0" => length - index - 1,
              "first"   => (index == 0),
              "last"    => (index == length - 1),
            })

            result << render_all(@for_block, context)

            # Handle any interrupts if they exist.
            if context.has_interrupt?
              interrupt = context.pop_interrupt
              break if interrupt.is_a? BreakInterrupt
              next if interrupt.is_a? ContinueInterrupt
            end
          end
        end
      end
    end

    private def render_else(context)
      @else_block ? render_all(@else_block, context) : ""
    end
  end

  Template.register_tag("for", For)
end
