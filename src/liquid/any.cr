module Liquid
  class Any
    getter raw : Type

    def initialize(raw)
      @raw = raw
      @uninitialized = false
    end

    def initialize(any : Any)
      @uninitialized = false
      any
    end

    def initialize
      @raw = nil
      @uninitialized = true
    end

    def include?(other : Any)
      case object = @raw
      when Array
        object.includes?(other.raw)
      when String
        object.includes?(other.raw.to_s)
      else
        false
      end
    end

    def compare(op : String, other : Any)
      case object = @raw
      when Int
        num_compare(op, object.as Int, other)
      when Float
        num_compare(op, object.as Float, other)
      when String
        string_compare(op, object.as String, other)
      else
        false
      end
    end

    def uninitialized?
      @uninitialized
    end

    def has_key?(key : Type)
      case object = @raw
      when Array
        if key.is_a?(Int)
          return key > -1 && key < object.size
        else
          return false
        end
      when Hash
        return object.has_key?(key)
      else
        return false
        # raise "expected Array or Hash for #has_key?(key : Type), " \
        #       "not #{object.class}"
      end
    end

    def [](index : Int) : Any
      case object = @raw
      when Array, Hash
        Any.new object[index]
      else
        raise "expected Array or Hash for #[](index : Int), not #{object.class}"
      end
    end

    # Assumes the underlying value is a Hash and returns the element
    # with the given key.
    # Raises if the underlying value is not a Hash.
    def [](key : Type) : Any
      case object = @raw
      when Array
        if key.is_a?(Int)
          index = key
          value = object[index]?
          Any.new(value)
        else
          Any.new(nil)
        end
      when Hash
        Any.new(object.fetch(key) { nil })
      else
        raise "expected Array or Hash for #[](key : String), not #{object.class}"
      end
    end

    def []?(key : Type) : Any
      case object = @raw
      when Array
        if key.is_a?(Int)
          index = key
          value = object[index]?
          Any.new(value)
        else
          Any.new(nil)
        end
      when Hash
        Any.new(object.fetch(key) { nil })
      else
        raise "expected Array or Hash for #[](key : String), not #{object.class}"
      end
    end

    def []=(key : String | Int, value : Type) : Type
      case object = @raw
      when Array
        if key.is_a?(Int)
          index = key
          object[index] = value
        else
          raise "expected Hash for #[](key : String), not #{object.class}"
        end
      when Hash
        object[key] = value
      else
        raise "expected Array or Hash for #[](key : String), not #{object.class}"
      end
      value
    end

    def each
      if (raw = @raw).responds_to?(:each)
        raw.each do |element|
          yield element
        end
      elsif (raw = @raw).responds_to?(:each_char)
        raw.each_char do |element|
          yield element.to_s
        end
      end
    end

    def iterable?
      @raw.responds_to?(:each) || non_blank_string?
    end

    def non_blank_string?
      @raw.is_a?(String) && @raw != ""
    end

    def to_i
      to_s.to_i
    end

    def to_liquid
      @raw.to_liquid
    end

    def to_s
      @raw.to_s
    end

    private def num_compare(op : String, num : Int | Float, other : Any)
      case object = other.raw
      when Int, Float
        case op
        when "<"
          num < object
        when ">"
          num > object
        when ">="
          num >= object
        when "<="
          num <= object
        else
          raise "undefined op '#{op}'"
        end
      else
        false
      end
    end

    private def string_compare(op : String, str : String, other : Any)
      case object = other.raw
      when String
        case op
        when "<"
          str < object
        when ">"
          str > object
        when ">="
          str >= object
        when "<="
          str <= object
        else
          raise "undefined op '#{op}'"
        end
      else
        false
      end
    end
  end
end
