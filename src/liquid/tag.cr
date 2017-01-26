module Liquid
  class Tag
    property :nodelist

    def initialize(tag_name : String, markup : String, tokens)
      @nodelist = [] of String | Tag | Variable
      @tag_name = tag_name
      @markup = markup
      parse(tokens)
    end

    def parse(tokens)
    end

    def name
      self.class.name.downcase
    end

    def render(context)
      ""
    end
  end # Tag

end # Tag
