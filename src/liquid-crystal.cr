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
  FilterSeparator            = /\|/
  ArgumentSeparator          = ','
  FilterArgumentSeparator    = ':'
  VariableAttributeSeparator = '.'
  TagStart                   = /\{\%/
  TagEnd                     = /\%\}/
  VariableSignature          = /\(?[\w\-\.\[\]]\)?/
  VariableSegment            = /[\w\-]/
  VariableStart              = /\{\{/
  VariableEnd                = /\}\}/
  VariableIncompleteEnd      = /\}\}?/
  QuotedString               = /"[^"]*"|'[^']*'/
  QuotedFragment             = /#{QuotedString}|(?:[^\s,\|'"]|#{QuotedString})+/
  StrictQuotedFragment       = /"[^"]+"|'[^']+'|[^\s|:,]+/
  FirstFilterArgument        = /#{FilterArgumentSeparator}(?:#{StrictQuotedFragment})/
  OtherFilterArgument        = /#{ArgumentSeparator}(?:#{StrictQuotedFragment})/
  SpacelessFilter            = /^(?:'[^']+'|"[^"]+"|[^'"])*#{FilterSeparator}(?:#{StrictQuotedFragment})(?:#{FirstFilterArgument}(?:#{OtherFilterArgument})*)?/
  Expression                 = /(?:#{QuotedFragment}(?:#{SpacelessFilter})*)/
  TagAttributes              = /(\w+)\s*\:\s*(#{QuotedFragment})/
  AnyStartingTag             = /\{\{|\{\%/
  PartialTemplateParser      = /#{TagStart}.*?#{TagEnd}|#{VariableStart}.*?#{VariableIncompleteEnd}/
  TemplateParser             = /(#{PartialTemplateParser}|#{AnyStartingTag})/
  VariableParser             = /\[[^\]]+\]|#{VariableSegment}+\??/

  alias Type = Nil | Bool | Int32 | Float32 | Int64 | Float64 | String | Time | Liquid::Drop | Liquid::Context | Array(Type) | Hash(String, Type) | Range(Int32, Int32) | Symbol | Liquid::FileSystem
end

require "./liquid/context"
require "./liquid/drop"
require "./liquid/file_system"

require "./liquid/data"
require "./liquid/any"
require "./liquid/extensions"
require "./liquid/errors"
require "./liquid/interrupts"
require "./liquid/filter"
require "./liquid/register_collection"
require "./liquid/strainer"
require "./liquid/standard_filters"
require "./liquid/tag"
require "./liquid/block"
require "./liquid/document"
require "./liquid/variable"
require "./liquid/template"
require "./liquid/htmltags"
require "./liquid/condition"
require "./liquid/utils"
#
# # Load all the tags of the standard library
# #
require "./liquid/tags/*"
