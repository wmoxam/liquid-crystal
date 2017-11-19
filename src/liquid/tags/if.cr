module Liquid
  # If is the conditional block
  #
  #   {% if user.admin %}
  #     Admin user!
  #   {% else %}
  #     Not admin user
  #   {% endif %}
  #
  #    There are {% if count < 5 %} less {% else %} more {% endif %} items
  #    than you need.
  #
  #
  class If < Block
    SyntaxHelp = "Syntax Error in tag 'if' - Valid syntax: if [expression]"
    Syntax     = /(#{QuotedFragment})\s*([=!<>a-z_]+)?\s*(#{QuotedFragment})?/
    ExpressionsAndOperators = /(?:\b(?:\s?and\s?|\s?or\s?)\b|(?:\s*(?!\b(?:\s?and\s?|\s?or\s?)\b)(?:#{QuotedFragment}|\S+)\s*)+)/

    def initialize(tag_name, markup, tokens)
      @blocks = [] of Condition
      @nodelist = [] of String | Tag | Variable
      @tag_name = tag_name
      @markup = markup

      push_block("if", markup)
      parse(tokens)
    end

    def unknown_tag(tag, markup, tokens)
      if ["elsif", "else"].includes?(tag)
        push_block(tag, markup)
      else
        super
      end
    end

    def render(context)
      context.stack do
        @blocks.each do |block|
          if block.evaluate(context)
            return render_all(block.attachment, context)
            #return render_all(@nodelist, context)
          end
        end
        ""
      end
    end

    private def push_block(tag, markup)
      block = if tag == "else"
        ElseCondition.new
      else
        expressions = markup.scan(ExpressionsAndOperators).reverse
        expr_arr = expressions.shift?
        expr = if expr_arr
          expr_arr[0]?
        else
          nil
        end
        syntax_match = expr.nil? ? nil : expr.match(Syntax)

        raise(SyntaxError.new "SyntaxHelp 1") if syntax_match.nil?

        condition = Condition.new(syntax_match[1]?,
                                  syntax_match[2]?,
                                  syntax_match[3]?)

        while !expressions.empty?
          operator = (expressions.shift)[0].to_s.strip
          expr = expressions.shift[0]?
          syntax_match = expr.nil? ? nil : expr.match(Syntax)

          raise(SyntaxError.new "SyntaxHelp 2") if syntax_match.nil?

          new_condition = Condition.new(syntax_match[1]?,
                                        syntax_match[2]?,
                                        syntax_match[3]?)

          case operator
          when "and"
            new_condition.and(condition)
          when "or"
            new_condition.or(condition)
          else
            raise SyntaxError.new "invalid boolean operator"
          end
          condition = new_condition
        end

        condition
      end

      @blocks.push(block)
      @nodelist = block.attach(Array(Tag | Variable | String).new)
    end
  end

  Template.register_tag("if", If)
end
