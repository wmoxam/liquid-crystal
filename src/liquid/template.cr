module Liquid
  # Templates are central to liquid.
  # Interpretating templates is a two step process. First you compile the
  # source code you got. During compile time some extensive error checking is
  # performed. Your code should expect to get some SyntaxErrors.
  #
  # After you have a compiled template you can then <tt>render</tt> it.
  # You can use a compiled template over and over again and keep it cached.
  #
  # Example:
  #
  #   template = Liquid::Template.parse(source)
  #   template.render("user_name" => "bob")
  #
  class Template
    property :root

    @@file_system = FileSystem.new
    @@file_system = BlankFileSystem.new

    def self.file_system
      @@file_system
    end

    def self.file_system=(obj)
      @@file_system = obj
    end

    def self.register_tag(name, klass)
      tags[name.to_s] = klass
    end

    def self.tags
      @@tags ||= {} of String => Tag.class
    end

    # Pass a module with filter methods which should be available
    # to all liquid views. Good for registering the standard library
    def self.register_filter(filter : Filter.class)
      Strainer.global_filter(filter)
    end

    # creates a new <tt>Template</tt> object from liquid source code
    def self.parse(source)
      template = Template.new
      template.parse(source)
      template
    end

    # creates a new <tt>Template</tt> from an array of tokens.
    # Use <tt>Template.parse</tt> instead
    def initialize
      @rethrow_errors = false
      @root = nil
    end

    # Parse source code.
    # Returns self for easy chaining
    def parse(source)
      @root = Document.new(tokenize(source))
      self
    end

    def registers
      @registers ||= {} of Symbol => Type
    end

    def assigns
      @assigns ||= {} of String => Type
    end

    def instance_assigns
      @instance_assigns ||= {} of String => Type
    end

    def errors
      @errors ||= [] of Exception
    end

    # Render takes a hash with local variables.
    #
    # if you use the same filters over and over again consider registering
    # them globally
    # with <tt>Template.register_filter</tt>
    #
    # Following options can be passed:
    #
    #  * <tt>filters</tt> : array with local filters
    #  * <tt>registers</tt> : hash with register variables. Those can be
    # accessed from filters and tags and might be useful to integrate liquid
    # more with its host application
    def render(context : Context)
      begin
        # render the nodelist.
        # for performance reasons we get a array back here. join will
        # make a string out of it
        if @root.nil?
          ""
        else
          result = @root.not_nil!.render(context)
          result.responds_to?(:join) ? result.join : result
        end
      ensure
        @errors = context.errors
      end
    end

    def render(context : Context,
               registers : Hash(Symbol, Type),
               filters : Array(Filter.class))
      self.registers.merge!(registers)
      context.add_filters(filters)

      render context
    end

    def render(context : Context, registers : Hash(Symbol, Type))
      self.registers.merge!(registers)
      render context
    end

    def render(context : Context, filters : Array(Filter.class))
      context.add_filters(filters)
      render context
    end

    def render(environment)
      render Context.new([Data.prepare(environment), assigns],
        instance_assigns,
        registers,
        @rethrow_errors)
    end

    def render(environment,
               registers : Hash(Symbol, Type),
               filters : Array(Filter.class))
      context = Context.new([Data.prepare(environment), assigns],
        instance_assigns,
        registers,
        @rethrow_errors)
      self.registers.merge!(registers)
      context.add_filters(filters)

      render context
    end

    def render(environment,
               registers : Hash(Symbol, Type))
      context = Context.new([Data.prepare(environment), assigns],
        instance_assigns,
        registers,
        @rethrow_errors)
      self.registers.merge!(registers)
      render context
    end

    def render(environment,
               filters : Array(Filter.class))
      context = Context.new([Data.prepare(environment), assigns],
        instance_assigns,
        registers,
        @rethrow_errors)
      context.add_filters(filters)

      render context
    end

    def render
      render Context.new([assigns], instance_assigns, registers, @rethrow_errors)
    end

    def render!(*args)
      @rethrow_errors = true; render(*args)
    end

    # Uses the <tt>Liquid::TemplateParser</tt> regexp to tokenize the
    # passed source
    private def tokenize(source)
      source = source.source if source.responds_to?(:source)
      source = source.to_s
      return [] of String if source.to_s.empty?
      tokens = source.split(TemplateParser)

      # removes the rogue empty element at the beginning of the array
      tokens.shift if tokens[0] && tokens[0].empty?

      tokens
    end
  end
end
