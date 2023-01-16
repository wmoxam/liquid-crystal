module Liquid
  # Cycle is usually used within a loop to alternate between values, like
  # colors or DOM classes.
  #
  #   {% for item in items %}
  #     <div class="{% cycle 'red', 'green', 'blue' %}"> {{ item }} </div>
  #   {% end %}
  #
  #    <div class="red"> Item one </div>
  #    <div class="green"> Item two </div>
  #    <div class="blue"> Item three </div>
  #    <div class="red"> Item four </div>
  #    <div class="green"> Item five</div>
  #
  class Cycle < Tag
    SimpleSyntax = /^#{QuotedFragment}+/
    NamedSyntax  = /^(#{QuotedFragment})\s*\:\s*(.*)/

    @variables : Array(String)
    @name : String

    def initialize(tag_name, markup, tokens)
      case markup
      when NamedSyntax
        @variables = variables_from_string($2)
        @name = $1
      when SimpleSyntax
        @variables = variables_from_string(markup)
        @name = "'#{@variables.to_s}'"
      else
        raise SyntaxError.new("Syntax Error in 'cycle' - Valid syntax: " \
                              "cycle [name :] var [, var2, var3 ...]")
      end
      super
    end

    def render(context)
      cycle_hash = {} of String => Type

      if context.registers.has_key?(:cycle)
        if (hash = context.registers[:cycle].raw).is_a?(Hash)
          hash.each_key do |key|
            value = hash[key]
            cycle_hash[key] = value
          end
        end
      end

      context.stack do
        key = context[@name].to_s
        iteration = if cycle_hash[key]?
                      Any.new(cycle_hash[key]?.not_nil!).to_i
                    else
                      0
                    end
        result = context[@variables[iteration]]
        iteration += 1
        iteration = 0 if iteration >= @variables.size
        cycle_hash[key] = iteration.as(Type)
        context.registers[:cycle] = cycle_hash
        result
      end
    end

    private def variables_from_string(markup)
      markup.split(",").map do |var|
        var =~ /\s*(#{QuotedFragment})\s*/
        $1 || nil
      end.compact
    end
  end

  Template.register_tag("cycle", Cycle)
end
