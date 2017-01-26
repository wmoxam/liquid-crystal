module Liquid
  class Include < Tag
    Syntax = /(#{QuotedFragment}+)(\s+(?:with|for)\s+(#{QuotedFragment}+))?/

    @template_name: String
    @variable_name: String | Nil

    def initialize(tag_name, markup, tokens)
      if markup =~ Syntax

        @template_name = $1
        @variable_name = $3?
        @attributes    = {} of String => Type

        markup.scan(TagAttributes) do |match|
          @attributes[match[1]?.not_nil!] = match[2]?
        end
      else
        raise SyntaxError.new("Error in tag 'include' - Valid syntax: include '[template]' (with|for) [object|collection]")
      end

      super
    end

    def parse(tokens)
    end

    def render(context)
      source = _read_template_from_file_system(context)
      partial = Liquid::Template.parse(source)
      variable = context[@variable_name || @template_name[1..-2]]

      context.stack do
        @attributes.each do |key, value|
          context[key] = context[value]
        end

        if variable.is_a?(Array)
          variable.map do |variable|
            context[@template_name[1..-2]] = variable
            partial.render(context).as String
          end.join
        else
          context[@template_name[1..-2]] = variable
          partial.render(context)
        end
      end
    end

    private def _read_template_from_file_system(context)
      file_system = if context.registers.has_key?(:file_system)
        context.registers[:file_system].raw.as(FileSystem)
      else
        Liquid::Template.file_system
      end

      file_system.read_template_file(context[@template_name], context)
    end
  end

  Template.register_tag("include", Include)
end
