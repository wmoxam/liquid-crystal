require "../../test_helper"

class StandardTagTest < Minitest::Test
  include Liquid
  include Liquid::Data

  # def test_tag
  #   tag = Tag.new('tag', [], [])
  #   assert_equal 'liquid::tag', tag.name
  #   assert_equal '', tag.render(Context.new)
  # end

  def test_no_transform
    assert_template_result("this text should come out of the template without change...",
                           "this text should come out of the template without change...")

    assert_template_result("blah","blah")
    assert_template_result("<blah>","<blah>")
    assert_template_result("|,.:","|,.:")
    assert_template_result("","")

    text = "this shouldnt see any transformation either but has multiple lines
              as you can clearly see here ..."
    assert_template_result(text,text)
  end

  def test_has_a_block_which_does_nothing
    assert_template_result("the comment block should be removed  .. right?",
                           "the comment block should be removed {%comment%} be gone.. {%endcomment%} .. right?")

    assert_template_result("","{%comment%}{%endcomment%}")
    assert_template_result("","{%comment%}{% endcomment %}")
    assert_template_result("","{% comment %}{%endcomment%}")
    assert_template_result("","{% comment %}{% endcomment %}")
    assert_template_result("","{%comment%}comment{%endcomment%}")
    assert_template_result("","{% comment %}comment{% endcomment %}")

    assert_template_result("foobar","foo{%comment%}comment{%endcomment%}bar")
    assert_template_result("foobar","foo{% comment %}comment{% endcomment %}bar")
    assert_template_result("foobar","foo{%comment%} comment {%endcomment%}bar")
    assert_template_result("foobar","foo{% comment %} comment {% endcomment %}bar")

    assert_template_result("foo  bar","foo {%comment%} {%endcomment%} bar")
    assert_template_result("foo  bar","foo {%comment%}comment{%endcomment%} bar")
    assert_template_result("foo  bar","foo {%comment%} comment {%endcomment%} bar")

    assert_template_result("foobar","foo{%comment%}
                                     {%endcomment%}bar")
  end

  def test_assign
    assigns = _h({"var" => "content" })
    assert_template_result("var2:  var2:content", "var2:{{var2}} {%assign var2 = var%} var2:{{var2}}", assigns)

  end

  def test_hyphenated_assign
    assigns = _h({"a-b" => "1" })
    assert_template_result("a-b:1 a-b:2", "a-b:{{a-b}} {%assign a-b = 2 %}a-b:{{a-b}}", assigns)

  end

  def test_assign_with_colon_and_spaces
    assigns = _h({"var" => {"a:b c" => {"paged" => "1" }}})
    assert_template_result("var2: 1", "{%assign var2 = var['a:b c'].paged %}var2: {{var2}}", assigns)
  end

  def test_capture
    assigns = _h({"var" => "content" })
    assert_template_result("content foo content foo ",
                           "{{ var2 }}{% capture var2 %}{{ var }} foo {% endcapture %}{{ var2 }}{{ var2 }}",
                           assigns)
  end

  def test_capture_detects_bad_syntax
    assert_raises(SyntaxError) do
      assert_template_result("content foo content foo ",
                             "{{ var2 }}{% capture %}{{ var }} foo {% endcapture %}{{ var2 }}{{ var2 }}",
                             _h({"var" => "content" }))
    end
  end

  def test_case
    assigns = _h({"condition" => 2 })
    assert_template_result(" its 2 ",
                           "{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}",
                           assigns)

    assigns = _h({"condition" => 1 })
    assert_template_result(" its 1 ",
                           "{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}",
                           assigns)

    assigns = _h({"condition" => 3 })
    assert_template_result("",
                           "{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}",
                           assigns)

    assigns = _h({"condition" => "string here" })
    assert_template_result(" hit ",
                           "{% case condition %}{% when \"string here\" %} hit {% endcase %}",
                           assigns)

    assigns = _h({"condition" => "bad string here" })
    assert_template_result("",
                           "{% case condition %}{% when \"string here\" %} hit {% endcase %}",\
                           assigns)
  end

  def test_case_with_else
    assigns = _h({"condition" => 5 })
    assert_template_result(" hit ",
                           "{% case condition %}{% when 5 %} hit {% else %} else {% endcase %}",
                           assigns)

    assigns = _h({"condition" => 6 })
    assert_template_result(" else ",
                           "{% case condition %}{% when 5 %} hit {% else %} else {% endcase %}",
                           assigns)

    assigns = _h({"condition" => 6 })
    assert_template_result(" else ",
                           "{% case condition %} {% when 5 %} hit {% else %} else {% endcase %}",
                           assigns)
  end

  def test_case_on_size
    assert_template_result("",  "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", _h({"a" => [] of Int32}))
    assert_template_result("1", "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", _h({"a" => [1]}))
    assert_template_result("2", "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", _h({"a" => [1, 1]}))
    assert_template_result("",  "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", _h({"a" => [1, 1, 1]}))
    assert_template_result("",  "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", _h({"a" => [1, 1, 1, 1]}))
    assert_template_result("",  "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", _h({"a" => [1, 1, 1, 1, 1]}))
  end

  def test_case_on_size_with_else
    assert_template_result("else",
                           "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
                           _h({"a" => [] of Type}))

    assert_template_result("1",
                           "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
                           _h({"a" => [1]}))

    assert_template_result("2",
                           "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
                           _h({"a" => [1, 1]}))

    assert_template_result("else",
                           "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
                           _h({"a" => [1, 1, 1]}))

    assert_template_result("else",
                           "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
                           _h({"a" => [1, 1, 1, 1]}))

    assert_template_result("else",
                           "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
                           _h({"a" => [1, 1, 1, 1, 1]}))
  end

  def test_case_on_length_with_else
    empty = {} of String => Type
    assert_template_result("else",
                           "{% case a.empty? %}{% when true %}true{% when false %}false{% else %}else{% endcase %}",
                           empty)

    assert_template_result("false",
                           "{% case false %}{% when true %}true{% when false %}false{% else %}else{% endcase %}",
                           empty)

    assert_template_result("true",
                           "{% case true %}{% when true %}true{% when false %}false{% else %}else{% endcase %}",
                           empty)

    assert_template_result("else",
                           "{% case NULL %}{% when true %}true{% when false %}false{% else %}else{% endcase %}",
                           empty)
  end

  def test_assign_from_case
    # Example from the shopify forums
    code = %q({% case collection.handle %}{% when 'menswear-jackets' %}{% assign ptitle = 'menswear' %}{% when 'menswear-t-shirts' %}{% assign ptitle = 'menswear' %}{% else %}{% assign ptitle = 'womenswear' %}{% endcase %}{{ ptitle }})
    template = Liquid::Template.parse(code)
    assert_equal "menswear",   template.render(_h({"collection" => {"handle" => "menswear-jackets"}}))
    assert_equal "menswear",   template.render(_h({"collection" => {"handle" => "menswear-t-shirts"}}))
    assert_equal "womenswear", template.render(_h({"collection" => {"handle" => "x"}}))
    assert_equal "womenswear", template.render(_h({"collection" => {"handle" => "y"}}))
    assert_equal "womenswear", template.render(_h({"collection" => {"handle" => "z"}}))
  end

  def test_case_when_or
    code = "{% case condition %}{% when 1 or 2 or 3 %} its 1 or 2 or 3 {% when 4 %} its 4 {% endcase %}"
    assert_template_result(" its 1 or 2 or 3 ", code, _h({"condition" => 1 }))
    assert_template_result(" its 1 or 2 or 3 ", code, _h({"condition" => 2 }))
    assert_template_result(" its 1 or 2 or 3 ", code, _h({"condition" => 3 }))
    assert_template_result(" its 4 ", code, _h({"condition" => 4 }))
    assert_template_result("", code, _h({"condition" => 5 }))

    code = "{% case condition %}{% when 1 or \"string\" or null %} its 1 or 2 or 3 {% when 4 %} its 4 {% endcase %}"
    assert_template_result(" its 1 or 2 or 3 ", code, _h({"condition" => 1 }))
    assert_template_result(" its 1 or 2 or 3 ", code, _h({"condition" => "string" }))
    assert_template_result(" its 1 or 2 or 3 ", code, _h({"condition" => nil }))
    assert_template_result("", code, _h({"condition" => "something else" }))
  end

  def test_case_when_comma
    code = "{% case condition %}{% when 1, 2, 3 %} its 1 or 2 or 3 {% when 4 %} its 4 {% endcase %}"
    assert_template_result(" its 1 or 2 or 3 ", code, _h({"condition" => 1 }))
    assert_template_result(" its 1 or 2 or 3 ", code, _h({"condition" => 2 }))
    assert_template_result(" its 1 or 2 or 3 ", code, _h({"condition" => 3 }))
    assert_template_result(" its 4 ", code, _h({"condition" => 4 }))
    assert_template_result("", code, _h({"condition" => 5 }))

    code = "{% case condition %}{% when 1, \"string\", null %} its 1 or 2 or 3 {% when 4 %} its 4 {% endcase %}"
    assert_template_result(" its 1 or 2 or 3 ", code, _h({"condition" => 1 }))
    assert_template_result(" its 1 or 2 or 3 ", code, _h({"condition" => "string" }))
    assert_template_result(" its 1 or 2 or 3 ", code, _h({"condition" => nil }))
    assert_template_result("", code, _h({"condition" => "something else" }))
  end

  def test_assign
    assert_equal "variable", Liquid::Template.parse( "{% assign a = \"variable\"%}{{a}}"  ).render
  end

  def test_assign_an_empty_string
    assert_equal "", Liquid::Template.parse( "{% assign a = \"\"%}{{a}}"  ).render
  end

  def test_assign_is_global
    assert_equal "variable",
                 Liquid::Template.parse( "{%for i in (1..2) %}{% assign a = 'variable'%}{% endfor %}{{a}}"  ).render
  end

  def test_case_detects_bad_syntax
    assert_raises(SyntaxError) do
      assert_template_result("",  "{% case false %}{% when %}true{% endcase %}", _h({} of String => Type))
    end

    assert_raises(SyntaxError) do
      assert_template_result("",  "{% case false %}{% huh %}true{% endcase %}", _h({} of String => Type))
    end
  end

  def test_cycle
    assert_template_result("one","{%cycle \"one\", \"two\"%}")
    assert_template_result("one two","{%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%}")
    assert_template_result(" two","{%cycle \"\", \"two\"%} {%cycle \"\", \"two\"%}")

    assert_template_result("one two one","{%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%}")

    assert_template_result("text-align: left text-align: right",
      "{%cycle \"text-align: left\", \"text-align: right\" %} {%cycle \"text-align: left\", \"text-align: right\"%}")
  end

  def test_multiple_cycles
    assert_template_result("1 2 1 1 2 3 1",
      "{%cycle 1,2%} {%cycle 1,2%} {%cycle 1,2%} {%cycle 1,2,3%} {%cycle 1,2,3%} {%cycle 1,2,3%} {%cycle 1,2,3%}")
  end

  def test_multiple_named_cycles
    assert_template_result("one one two two one one",
      %[{%cycle 1: "one", "two" %} {%cycle 2: "one", "two" %} {%cycle 1: "one", "two" %} {%cycle 2: "one", "two" %} {%cycle 1: "one", "two" %} {%cycle 2: "one", "two" %}])
  end

  def test_multiple_named_cycles_with_names_from_context
    assigns = _h({"var1" => 1, "var2" => 2 })
    assert_template_result("one one two two one one",
      %[{%cycle var1: "one", "two" %} {%cycle var2: "one", "two" %} {%cycle var1: "one", "two" %} {%cycle var2: "one", "two" %} {%cycle var1: "one", "two" %} {%cycle var2: "one", "two" %}], assigns)
  end

  def test_size_of_array
    assigns = _h({"array" => [1,2,3,4]})
    assert_template_result("array has 4 elements", "array has {{ array.size }} elements", assigns)
  end

  # def test_size_of_hash
  #   assigns = _h({"hash" => {"a" => 1, "b" => 2, "c" => 3, "d" => 4}})
  #   assert_template_result("hash has 4 elements", "hash has {{ hash.size }} elements", assigns)
  # end

  def test_illegal_symbols
    assert_template_result("", "{% if true == empty %}?{% endif %}", {} of String => Type)
    assert_template_result("", "{% if true == null %}?{% endif %}", {} of String => Type)
    assert_template_result("", "{% if empty == true %}?{% endif %}", {} of String => Type)
    assert_template_result("", "{% if null == true %}?{% endif %}", {} of String => Type)
  end

  def test_ifchanged
    assigns = _h({"array" => [ 1, 1, 2, 2, 3, 3] })
    assert_template_result("123","{%for item in array%}{%ifchanged%}{{item}}{% endifchanged %}{%endfor%}",assigns)

    assigns = _h({"array" => [ 1, 1, 1, 1] })
    assert_template_result("1","{%for item in array%}{%ifchanged%}{{item}}{% endifchanged %}{%endfor%}",assigns)
  end
end # StandardTagTest
