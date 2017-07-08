module Liquid
  class Case < Block
    Syntax     = /(#{QuotedFragment})/
    WhenSyntax = /(#{QuotedFragment})(?:(?:\s+or\s+|\s*\,\s*)(#{QuotedFragment}.*))?/

    @left : Type

    def initialize(tag_name, markup, tokens)
      @blocks = [] of Condition

      if markup =~ Syntax
        @left = $1
      else
        raise SyntaxError.new("Syntax Error in tag 'case' - Valid syntax: " \
          "case [condition]")
      end

      super
    end

    def unknown_tag(tag, markup, tokens)
      @nodelist = [] of Liquid::Tag | Liquid::Variable | String
      case tag
      when "when"
        record_when_condition(markup)
      when "else"
        record_else_condition(markup)
      else
        super
      end
    end

    def render(context)
      context.stack do
        execute_else_block = true
        String.build do |output|
          @blocks.each do |block|
            if block.else? && execute_else_block
              return render_all(block.attachment, context)
            elsif !block.else? && block.evaluate(context)
              execute_else_block = false
              output << render_all(block.attachment, context)
            end
          end
        end
      end
    end

    private def record_when_condition(markup)
      remaining_markup = markup.dup

      while !remaining_markup.nil?
        # Create a new nodelist and assign it to the new block
        match_data = WhenSyntax.match(remaining_markup)

        if match_data.nil?
          raise SyntaxError.new("Syntax Error in tag 'case' - Valid when " \
            "condition: {% when [condition] [or condition2...] %} ")
        else
          block = Condition.new(@left, "==", match_data[1])
          block.attach(@nodelist)
          @blocks.push(block)

          remaining_markup = match_data[2]?
        end
      end
    end

    private def record_else_condition(markup)
      if !markup.strip.empty?
        raise SyntaxError.new("Syntax Error in tag 'case' - Valid else " \
          "condition: {% else %} (no parameters) ")
      end

      block = ElseCondition.new
      block.attach(@nodelist)
      @blocks << block
    end

  end

  Template.register_tag("case", Case)
end
