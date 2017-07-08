# Copyright (c) 2005 Tobias Luetke
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module Liquid
  FilterSeparator             = /\|/
  ArgumentSeparator           = ','
  FilterArgumentSeparator     = ':'
  VariableAttributeSeparator  = '.'
  TagStart                    = /\{\%/
  TagEnd                      = /\%\}/
  VariableSignature           = /\(?[\w\-\.\[\]]\)?/
  VariableSegment             = /[\w\-]/
  VariableStart               = /\{\{/
  VariableEnd                 = /\}\}/
  VariableIncompleteEnd       = /\}\}?/
  QuotedString                = /"[^"]*"|'[^']*'/
  QuotedFragment              = /#{QuotedString}|(?:[^\s,\|'"]|#{QuotedString})+/
  StrictQuotedFragment        = /"[^"]+"|'[^']+'|[^\s|:,]+/
  FirstFilterArgument         = /#{FilterArgumentSeparator}(?:#{StrictQuotedFragment})/
  OtherFilterArgument         = /#{ArgumentSeparator}(?:#{StrictQuotedFragment})/
  SpacelessFilter             = /^(?:'[^']+'|"[^"]+"|[^'"])*#{FilterSeparator}(?:#{StrictQuotedFragment})(?:#{FirstFilterArgument}(?:#{OtherFilterArgument})*)?/
  Expression                  = /(?:#{QuotedFragment}(?:#{SpacelessFilter})*)/
  TagAttributes               = /(\w+)\s*\:\s*(#{QuotedFragment})/
  AnyStartingTag              = /\{\{|\{\%/
  PartialTemplateParser       = /#{TagStart}.*?#{TagEnd}|#{VariableStart}.*?#{VariableIncompleteEnd}/
  TemplateParser              = /(#{PartialTemplateParser}|#{AnyStartingTag})/
  VariableParser              = /\[[^\]]+\]|#{VariableSegment}+\??/

  alias Type = Nil | Bool | Int32 | Float32 | Int64 | Float64 | String | Time | Liquid::Drop | Array(Type) | Hash(String, Type) | Range(Int32, Int32) | Symbol | Tuple(Liquid::Type) | Liquid::FileSystem


end

require "./liquid/drop"
require "./liquid/file_system"

module Liquid
  module Data
    def _a(array)
      ([] of Type).tap do |normalized_array|
        array.each do |item|
          if item.is_a?(Array)
            normalized_array << _a(item)
          elsif item.is_a?(Hash)
            normalized_array << _h(item)
          else
            normalized_array << item.as Type
          end
        end
      end.as Type
    end

    def _h(hash)
      ({} of String => Type).tap do |normalized_hash|
        hash.each_key do |key|
          value = hash[key]
          if value.is_a?(Hash)
            normalized_hash[key] = _h(value).as Type
          elsif value.is_a?(Array)
            normalized_hash[key] = _a(value).as Type
          else
            normalized_hash[key] = value.as Type
          end
        end
      end
    end
  end

  class  Any
    getter raw : Type

    def initialize(raw)
      @raw = raw.as Type
      @uninitialized = false
    end

    def initialize(any : Any)
      @uninitialized = false
      any
    end

    def initialize()
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
        raise "expected Array or Hash for #has_key?(key : Type), " \
          "not #{object.class}"
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
        end
      else
        false
      end
    end
  end
end

require "./liquid/extensions"
require "./liquid/errors"
require "./liquid/interrupts"
require "./liquid/filter"
require "./liquid/register_collection"
require "./liquid/strainer"
require "./liquid/standard_filters"
require "./liquid/context"
require "./liquid/tag"
require "./liquid/block"
require "./liquid/document"
require "./liquid/variable"
require "./liquid/template"
require "./liquid/htmltags"
require "./liquid/condition"
# require 'liquid/module_ex'
require "./liquid/utils"
#
# # Load all the tags of the standard library
# #
require "./liquid/tags/*"
