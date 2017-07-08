module Liquid
  # Assign sets a variable in your template.
  #
  #   {% assign foo = 'monkey' %}
  #
  # You can then use the variable later in the page.
  #
  #  {{ foo }}
  #
  class Assign < Tag
    Syntax = /(#{VariableSignature}+)\s*=\s*(.*)\s*/

    def initialize(tag_name, markup, tokens)
      @to = ""
      @from = Variable.new ""
      if markup =~ Syntax
        @to = $1
        @from = Variable.new($2)
      else
        raise SyntaxError.new("Syntax Error in 'assign' - Valid syntax: " \
          "assign [var] = [source]")
      end

      super
    end

    def render(context)
      from_result = @from.render(context)

      if from_result.is_a?(Any)
        context.scopes.last[@to] = from_result.raw
      else
        context.scopes.last[@to] = from_result
      end
      ""
    end
  end

  Template.register_tag("assign", Assign)
end
