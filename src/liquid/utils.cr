module Liquid
  module Utils
    def self.slice_collection_using_each(collection, from, to)
      segments = Array(Type).new
      index = 0
      yielded = 0

      return [collection.raw.as(Type)] if collection.non_blank_string?

      collection.each do |item|
        if to && to <= index
          break
        end

        if from <= index
          segments.push item.as(Type)
        end

        index += 1
      end

      segments
    end
  end
end
