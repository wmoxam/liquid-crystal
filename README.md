[![Build Status](https://travis-ci.org/wmoxam/liquid-crystal.svg?branch=master)](https://travis-ci.org/wmoxam/liquid-crystal)

# Liquid template engine

A port of the [Liquid template engine](https://github.com/Shopify/liquid) to [Crystal](https://github.com/crystal-lang/crystal)

## Usage

```crystal
require "liquid"

include Liquid::Data

markup = "{% if user %}
<p>Hello {{ user.name }}!</p>
{% endif %}"

template = Liquid::Template.parse template

result = template.render(_h({"user" => {"name" => "Matz"}}))

# Hello Matz
```

# Development Status

It's still a WIP, however much of the code and specs have been converted. Work
needs to be done for added stability, adding missing filters, implementing
missing tests and improving the data passing interface which is a bit clunky
(ie: Liquid::Data)

## Todo

### Missing standard filters

* sort
* map
* strip_newlines
* newlines_to_br
* plus
* minus
* times
* divided_by
* modulo
* append
* prepend

### Missing tests

* Some tests for the ```remove``` filter
* Template tokenize tests
* All tests that expect an error raised
* Filter tests
* Half of the Drop & Context tests
* Half of the if/else tag tests
