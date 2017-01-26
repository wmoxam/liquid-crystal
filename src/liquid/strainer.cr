module Liquid

  # Strainer is the parent class for the filters system.
  # New filters are registered with the strainer class which is then instantiated for each liquid template render run.
  #
  # The Strainer only allows method calls defined in filters given to it via Strainer.global_filter,
  # Context#add_filters or Template.register_filter
  class Strainer #:nodoc:
    @@filter_classes = [] of Filter.class

    def initialize(@context : Nil | Context, filters = [] of Filter)
      @filters = filters
    end

    def self.global_filter(filter_class : Filter.class)
      @@filter_classes.push filter_class
    end

    def self.create(context)
      Strainer.new(context, @@filter_classes.map {|klass| klass.new(context) })
    end

    def add_filter(filter : Filter)
      @filters.push(filter) unless @filters.includes?(filter)
    end

    def invoke(method, *args) : Any
      @filters.reverse.each do |filter|  # last filter that matches wins
        result = filter.invoke(method, *args)
        if !result.is_a?(FilterNotInvokable)
          return Any.new(result.as Type)
        end
      end
      Any.new(args.first?)
    end

  end
end
