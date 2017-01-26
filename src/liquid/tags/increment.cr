module Liquid

  # increment is used in a place where one needs to insert a counter
  #     into a template, and needs the counter to survive across
  #     multiple instantiations of the template.
  #     (To achieve the survival, the application must keep the context)
  #
  #     if the variable does not exist, it is created with value 0.

  #   Hello: {% increment variable %}
  #
  # gives you:
  #
  #    Hello: 0
  #    Hello: 1
  #    Hello: 2
  #
  class Increment < Tag
    @variable: String

    def initialize(tag_name, markup, tokens)
      @variable = markup.strip

      super
    end

    def render(context)
      env = context.environments.first
      value = env[@variable]? ? Any.new(env[@variable]?).to_i : 0
      env[@variable] = value + 1
      value.to_s
    end
  end

  Template.register_tag("increment", Increment)
end
