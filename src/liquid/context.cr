module Liquid
  # Context keeps the variable stack and resolves variables, as well as keywords
  #
  #   context["variable"] = "testing"
  #   context["variable"] #=> "testing"
  #   context["true"]     #=> true
  #   context["10.2232"]  #=> 10.2232
  #
  #   context.stack do
  #      context["bob"] = "bobsen"
  #   end
  #
  #   context["bob"]  #=> nil  class Context

  class VariableParts
    getter parts : Array(String), first_part : Type

    def initialize(@parts, @first_part)
    end
  end

  class Context
    getter scopes : Array(Hash(String, Type)), :errors, :registers, :environments
    @literals : Hash(String, Type)

    FLOATS   = /^(-?\d[\d\.]+)$/
    INTEGERS = /^(-?\d+)$/
    RANGES   = /^\((\S+)\.\.(\S+)\)$/
    STRINGS  = /^['"](.*)['"]$/

    LITERALS = Regex.union([FLOATS, INTEGERS, RANGES, STRINGS])

    def initialize(environments = [] of Hash(String, Type),
                   outer_scope = {} of String => Type,
                   registers = {} of Symbol => Type,
                   rethrow_errors = false)
      @environments = environments
      @scopes = [outer_scope]
      @registers = RegisterCollection.new(registers)
      @errors = [] of Exception
      @rethrow_errors = rethrow_errors
      @interrupts = [] of Interrupt
      @literals = Liquid::Data.prepare({
        "nil"   => nil,
        "null"  => nil,
        ""      => nil,
        "true"  => true,
        "false" => false,
        "blank" => :blank?,
        "empty" => :empty?,
      })

      @variable_parts = {} of String => VariableParts

      squash_instance_assigns_with_environments
    end

    def strainer
      @strainer ||= Strainer.create(self)
    end

    # Adds filters to this context.
    #
    # Note that this does not register the filters with the main Template
    # object. see <tt>Template.register_filter</tt> for that
    def add_filters(filters : Array(Filter.class) | Filter.class)
      [filters].flatten.compact.each do |klass|
        strainer.add_filter(klass.new(self))
      end
    end

    # are there any not handled interrupts?
    def has_interrupt?
      !@interrupts.empty?
    end

    # push an interrupt to the stack. this interrupt is considered not handled.
    def push_interrupt(e)
      @interrupts.push(e)
    end

    # pop an interrupt from the stack
    def pop_interrupt
      @interrupts.pop
    end

    def handle_error(e)
      errors.push(e)
      raise e if @rethrow_errors

      case e
      when SyntaxError
        "Liquid syntax error: #{e.message}"
      else
        "Liquid error: #{e.message}"
      end
    end

    def invoke(method, *args)
      begin
        strainer.invoke(method, *args)
      rescue ex : Exception
        Any.new handle_error(ex)
      end
    end

    # Push new local scope on the stack. use <tt>Context#stack</tt> instead
    def push(new_scope = {} of String => Type)
      @scopes.unshift(new_scope)
      raise StackLevelError.new("Nesting too deep") if @scopes.size > 100
    end

    # Merge a hash of variables in the current local scope
    def merge(new_scopes)
      merged = @scopes[0].merge(Data.prepare(new_scopes)).as Hash(String, Type)
      @scopes[0] = merged
    end

    # Pop from the stack. use <tt>Context#stack</tt> instead
    def pop
      raise ContextError.new if @scopes.size == 1
      @scopes.shift
    end

    # Pushes a new local scope on the stack, pops it at the end of the block
    #
    # Example:
    #   context.stack do
    #      context["var"] = "hi"
    #   end
    #
    #   context["var]  #=> nil
    def stack(new_scope = {} of String => Type, &block)
      push(new_scope)
      raise StackLevelError.new("Nesting too deep") if @scopes.size > 100
      yield
    ensure
      pop
    end

    def clear_instance_assigns
      @scopes[0] = {} of String => Type
    end

    # Only allow String, Numeric, Hash, Array, Proc, Boolean or
    # <tt>Liquid::Drop</tt>
    def []=(key : String, value : Any)
      @scopes[0][key] = value.raw
    end

    def []=(key : String, value : Type)
      @scopes[0][key] = value
    end

    def [](key)
      resolve(key)
    end

    def fetch(key)
      resolve(key)
    end

    def has_key?(key)
      resolve(key) != nil
    end

    def to_liquid
      self
    end

    # Look up variable, either resolve directly after considering the name.
    # We can directly handle Strings, digits, floats and booleans (true,false).
    # If no match is made we lookup the variable in the current scope and
    # later move up to the parent blocks to see if we can resolve the variable
    #  somewhere up the tree.
    # Some special keywords return symbols. Those symbols are to be called on
    # the rhs object in expressions
    #
    # Example:
    #   products == empty #=> products.empty?
    private def resolve(key)
      if key.nil?
        return nil
      end

      if key.is_a?(String)
        if @literals.has_key?(key)
          return @literals[key]
        end

        is_variable = !LITERALS.match(key)

        value = if is_variable
                  variable(key)
                else
                  case key
                  when STRINGS
                    $1
                  when INTEGERS
                    $1.to_i
                  when RANGES
                    range_start = resolve($1).as Int32 | String
                    range_end = resolve($2).as Int32 | String
                    (range_start.to_i..range_end.to_i)
                  when FLOATS
                    $1.to_f
                  end
                end

        if !is_variable && key.is_a?(String)
          @literals[key] = value.as(Type)
        end

        value
      else
        variable(key)
      end
    end

    # Fetches an object starting at the local scope and then moving up the
    # hierachy
    private def find_variable(key)
      scope = @scopes.find { |s| s.has_key?(key) }
      lookup = nil

      if scope.nil?
        @environments.each do |e|
          lookup = lookup_and_evaluate(e, key)
          if lookup && !lookup.uninitialized?
            scope = e
            break
          end
        end
      end

      scope ||= @environments.last { nil } || @scopes.last { nil }

      # TODO: Returning + checking for nil rather than returining an
      # uninitialized Liquid::Any object triggers a compiler bug.
      if !lookup || lookup.uninitialized?
        lookup = lookup_and_evaluate(scope, key)
      end

      variable = lookup.to_liquid
      variable.context = self if variable.is_a?(Drop)
      # variable.context = self if variable.respond_to?(:context=)

      return variable
    end

    # Resolves namespaced queries gracefully.
    #
    # Example
    #  @context["hash"] = {"name" => "tobi"}
    #  assert_equal "tobi", @context["hash.name"]
    #  assert_equal "tobi", @context["hash["name"]"]
    private def variable(markup)
      square_bracketed = /^\[(.*)\]$/
      markup_string = markup.to_s
      unless @variable_parts[markup]?
        parts = markup_string.scan(VariableParser).map { |p| p[0]? }.compact

        first_part = parts.shift

        if first_part =~ square_bracketed
          first_part = resolve($1)
        end

        @variable_parts[markup_string] = VariableParts.new(parts, first_part.as(Type))
      end

      parts = @variable_parts[markup_string].parts
      first_part = @variable_parts[markup_string].first_part

      if object = find_variable(first_part)
        parts.each do |part|
          part = resolve($1) if part_resolved = (part =~ square_bracketed)
          # If object is a hash- or array-like object we look for the
          # presence of the key and if its available we return it

          if (object.is_a?(Hash) && has_key?(object, part))
            object = lookup_and_evaluate(object, part, true).to_liquid
          elsif (object.is_a?(Array) && part.is_a?(Int))
            object = lookup_and_evaluate(object, part).to_liquid
          elsif !part_resolved && ["size", "first", "last"].includes?(part)
            # Some special cases. If the part wasn't in square brackets and
            # no key with the same name was found we interpret following calls
            # as commands and call them on the current object
            raw = case part
                  when "first"
                    object.first if object.responds_to?(:first)
                  when "last"
                    object.last if object.responds_to?(:last)
                  when "size"
                    object.size if object.responds_to?(:size)
                  else
                    # impossible!
                  end
            object = raw.as Type
          elsif object.is_a?(Drop)
            object = object.invoke_drop(part).to_liquid.as Type
          else
            # No key was present with the desired value and it wasn't one of
            # the directly supported keywords either. The only thing we got
            # left is to return nil

            return nil
          end

          # If we are dealing with a drop here we have to
          object.context = self if object.is_a?(Drop)
        end
      end

      object
    end # variable

    private def lookup_and_evaluate(obj, key, known_has_key = false) : Any
      return Any.new(obj)[normalized_key(key)] if known_has_key # we already tested if it has a key

      if has_key?(obj, key)
        return Any.new(obj)[normalized_key(key)]
      else
        return Any.new
      end

      # if value.is_a?(Proc) && obj.respond_to?(:[]=)
      #   obj[key] = (value.arity == 0) ? value.call : value.call(self)
      # else
      #  value
      # end
    end # lookup_and_evaluate

    private def has_key?(obj, key)
      Any.new(obj).has_key?(normalized_key(key))
    end

    private def normalized_key(key)
      if key.is_a?(Regex::MatchData)
        key[0]?
      else
        key
      end
    end

    private def squash_instance_assigns_with_environments
      @scopes.last.each_key do |k|
        @environments.each do |env|
          if env.has_key?(k)
            value = lookup_and_evaluate(env, k, true)
            @scopes.last[k] = if value.nil?
                                nil
                              else
                                value.raw
                              end
            break
          end
        end
      end
    end # squash_instance_assigns_with_environments
  end   # Context

end # Liquid
