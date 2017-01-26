module Liquid
  class RegisterCollection
    def initialize(collection)
      @collection = {} of Symbol => Type
      add(collection)
    end

    def add(collection)
      @collection = @collection.merge(collection)
    end

    def [](key : Symbol)
      Any.new(@collection[key])
    end

    def []?(key : Symbol)
      Any.new(@collection[key]?)
    end

    def []=(key : Symbol, value : Type)
      @collection[key] = value
    end

    def has_key?(key : Symbol) : Bool
      @collection.has_key?(key)
    end

  end
end
