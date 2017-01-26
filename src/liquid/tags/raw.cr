module Liquid
  class Raw < Block
    def parse(tokens)
      @nodelist ||= [] of Tag | Variable | String
      @nodelist.clear

      while token = tokens.shift
        if token =~ FullToken
          if block_delimiter == $1
            end_tag
            return
          end
        end
        @nodelist << token if !token.empty?
      end
    end
  end

  Template.register_tag("raw", Raw)
end
