[![Build Status](https://travis-ci.org/wmoxam/liquid-crystal.svg?branch=master)](https://travis-ci.org/wmoxam/liquid-crystal)

# Liquid template engine

A port of the [Liquid template engine](https://github.com/Shopify/liquid) to [Crystal](https://github.com/crystal-lang/crystal)

## Usage

```crystal
require "liquid-crystal"

markup = "{% if user %}
<p>Hello {{ user.name }}!</p>
{% endif %}"

template = Liquid::Template.parse template

result = template.render({"user" => {"name" => "Matz"}})

# <p>Hello Matz</p>
```

# Development Status

It's still a WIP, however much of the code and specs have been converted. Work
needs to be done for added stability, adding missing filters, implementing
missing tests

## Todo

### Missing standard filters

* sort
* map

### Missing tests

* Template tokenize tests
* All tests that expect an error to *not* be raised

### Support for procs in templates

* I'm not sure if I actually want to support this