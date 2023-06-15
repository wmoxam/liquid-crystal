module Liquid
  class Data
    def self.prepare(array : Array(Type) | Array(String))
      convert_array(array)
    end

    def self.prepare(hash : Hash(String, Type))
      convert_hash(hash)
    end

    private def self.convert_array(array)
      ([] of Type).tap do |normalized_array|
        array.each do |item|
          if item.is_a?(Array)
            normalized_array << convert_array(item)
          elsif item.is_a?(Hash)
            normalized_array << convert_hash(item)
          else
            normalized_array << item.as Type
          end
        end
      end.as Type
    end

    private def self.convert_hash(hash)
      ({} of String => Type).tap do |normalized_hash|
        hash.each_key do |key|
          value = hash[key]
          if value.is_a?(Hash)
            normalized_hash[key] = convert_hash(value).as Type
          elsif value.is_a?(Array)
            normalized_hash[key] = convert_array(value).as Type
          else
            normalized_hash[key] = value.as Type
          end
        end
      end
    end
  end
end
