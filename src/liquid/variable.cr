module Liquid
  # Holds variables. Variables are only loaded "just in time"
  # and are not evaluated as part of the render stage
  #
  #   {{ monkey }}
  #   {{ user.name }}
  #
  # Variables can be combined with filters:
  #
  #   {{ user | link }}
  #

  struct FilterParams
    property filtername
    property filterargs

    def initialize(@filtername : String, @filterargs : Array(String))
    end
  end

  class Variable
    FilterParser = /(?:#{FilterSeparator}|(?:\s*(?:#{QuotedFragment}|#{ArgumentSeparator})\s*)+)/
    getter :filters, :name

    def initialize(markup : String)
      @markup = markup
      @name = uninitialized String
      @filters = [] of FilterParams
      if name_match = markup.match(/\s*(#{QuotedFragment})(.*)/)
        @name = name_match[1]
        if filter_match = name_match[2].match(/#{FilterSeparator}\s*(.*)/)
          filters = filter_match[1].scan(FilterParser)
          filters.each do |f|
            if f && (matches = f[0].match(/\s*(\w+)(?:\s*#{FilterArgumentSeparator}(.*))?/))
              filtername = matches[1]
              filterargs = if matches[2]?.nil?
                [] of String
              else
                matches[2].to_s.scan(/(?:\A|#{ArgumentSeparator})\s*((?:\w+\s*\:\s*)?#{QuotedFragment})/).flatten.map { |m| m[1]?.to_s.strip }
              end

              @filters << FilterParams.new(filtername, filterargs)
            end
          end
        end
      end
    end

    def render(context)
      return "" if @name.nil?
      @filters.reduce(context[@name]) do |output, filter|
        if output.is_a?(Any)
          output = output.raw
        end

        filterargs = [] of Type
        keyword_args = {} of String => Type
        filter.filterargs.each do |a|
          if matches = a.match(/\A#{TagAttributes}\z/)
            keyword_args[matches[1]] = context[matches[2]]
          else
            filterargs << context[a]
          end
        end
        filterargs << keyword_args unless keyword_args.empty?
        begin
          # TODO: There's gotta be a better way ...
          case filterargs.size
          when 0
            context.invoke(filter.filtername, output)
          when 1
            context.invoke(filter.filtername, output,
                           *Tuple(Type).from(filterargs))
          when 2
            context.invoke(filter.filtername, output,
                           *Tuple(Type, Type).from(filterargs))
          when 3
            context.invoke(filter.filtername, output,
                           *Tuple(Type, Type, Type).from(filterargs))
          when 4
            context.invoke(filter.filtername, output,
                           *Tuple(Type, Type, Type, Type).from(filterargs))
          when 5
            context.invoke(filter.filtername, output,
                           *Tuple(Type, Type, Type, Type, Type).from(filterargs))
          else
            raise "Currently no support for more than 5 arguments, sorry!"
          end
        rescue FilterNotFound
          raise FilterNotFound.new "Error - filter '#{filter.filtername}' in" \
           " '#{@markup.strip}' could not be found."
        end
      end
    end
  end
end
