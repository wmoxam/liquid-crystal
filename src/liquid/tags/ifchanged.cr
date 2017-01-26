module Liquid
  class Ifchanged < Block

    def render(context)
      context.stack do

        output = render_all(@nodelist, context)

        has_value = context.registers[:ifchanged]?
        last_value = has_value ? context.registers[:ifchanged]?.not_nil!.raw : nil

        if has_value && output != last_value
          context.registers[:ifchanged] = output
          output
        else
          ""
        end
      end
    end
  end

  Template.register_tag("ifchanged", Ifchanged)
end
