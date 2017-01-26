module Liquid
  class Document < Block
    # we don't need markup to open this block
    def initialize(tokens)
      @tag_name = ""
      @markup = ""
      @nodelist = [] of String | Tag | Variable
      parse(tokens)
    end

    def initialize(tag_name, markup, tokens)
      @tag_name = ""
      @markup = ""
      @nodelist = [] of String | Tag | Variable
      parse(tokens)
    end

    # There isn't a real delimter
    def block_delimiter
      [] of String
    end

    # Document blocks don't need to be terminated since they are not actually opened
    def assert_missing_delimitation!
    end
  end
end
