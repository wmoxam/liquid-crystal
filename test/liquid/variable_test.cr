require "../test_helper"

class VariableTest < Minitest::Test
  include Liquid

  def test_variable
    var = Variable.new("hello")
    assert_equal "hello", var.name
  end

  def test_filters
    var = Variable.new("hello | textileze")
    assert_equal "hello", var.name
    var.filters.first.tap do |filter|
      assert_equal "textileze", filter.filtername
      assert_equal 0, filter.filterargs.size
    end

    var = Variable.new("hello | textileze | paragraph")
    assert_equal "hello", var.name
    var.filters.first.tap do |filter|
      assert_equal "textileze", filter.filtername
    end
    var.filters.last.tap do |filter|
      assert_equal "paragraph", filter.filtername
    end

    var = Variable.new(%( hello | strftime: '%Y'))
    assert_equal "hello", var.name
    var.filters.first.tap do |filter|
      assert_equal "strftime", filter.filtername
      assert_equal "'%Y'", filter.filterargs.first
    end

    var = Variable.new(%( 'typo' | link_to: 'Typo', true ))
    assert_equal %('typo'), var.name
    var.filters.first.tap do |filter|
      assert_equal "link_to", filter.filtername
      assert_equal "'Typo'", filter.filterargs.first
      assert_equal "true", filter.filterargs.last
    end

    var = Variable.new(%( 'typo' | link_to: 'Typo', false ))
    assert_equal %('typo'), var.name
    var.filters.first.tap do |filter|
      assert_equal "link_to", filter.filtername
      assert_equal "'Typo'", filter.filterargs.first
      assert_equal "false", filter.filterargs.last
    end

    var = Variable.new(%( 'foo' | repeat: 3 ))
    assert_equal %('foo'), var.name
    var.filters.first.tap do |filter|
      assert_equal "repeat", filter.filtername
      assert_equal "3", filter.filterargs.first
    end

    var = Variable.new(%( 'foo' | repeat: 3, 3 ))
    assert_equal %('foo'), var.name
    var.filters.first.tap do |filter|
      assert_equal "repeat", filter.filtername
      assert_equal "3", filter.filterargs[0]
      assert_equal "3", filter.filterargs[1]
    end

    var = Variable.new(%( 'foo' | repeat: 3, 3, 3 ))
    assert_equal %('foo'), var.name
    var.filters.first.tap do |filter|
      assert_equal "repeat", filter.filtername
      assert_equal "3", filter.filterargs[0]
      assert_equal "3", filter.filterargs[1]
      assert_equal "3", filter.filterargs[2]
    end

    var = Variable.new(%( hello | strftime: '%Y, okay?'))
    assert_equal "hello", var.name
    var.filters.first.tap do |filter|
      assert_equal "strftime", filter.filtername
      assert_equal "'%Y, okay?'", filter.filterargs.first
    end

    var = Variable.new(%( hello | things: "%Y, okay?", 'the other one'))
    assert_equal "hello", var.name
    var.filters.first.tap do |filter|
      assert_equal "things", filter.filtername
      assert_equal "\"%Y, okay?\"", filter.filterargs.first
      assert_equal "'the other one'", filter.filterargs.last
    end
  end

  def test_filter_with_date_parameter
    var = Variable.new(" '2006-06-06' | date: \"%m/%d/%Y\" ")
    assert_equal "'2006-06-06'", var.name
    var.filters.first.tap do |filter|
      assert_equal "date", filter.filtername
      assert_equal "\"%m/%d/%Y\"", filter.filterargs.first
    end
  end

  def test_filters_without_whitespace
    var = Variable.new("hello | textileze | paragraph")
    assert_equal "hello", var.name
    var.filters.first.tap do |filter|
      assert_equal "textileze", filter.filtername
    end
    var.filters.last.tap do |filter|
      assert_equal "paragraph", filter.filtername
    end

    var = Variable.new("hello|textileze|paragraph")
    assert_equal "hello", var.name
    var.filters.first.tap do |filter|
      assert_equal "textileze", filter.filtername
    end
    var.filters.last.tap do |filter|
      assert_equal "paragraph", filter.filtername
    end

    var = Variable.new("hello|replace:'foo','bar'|textileze")
    assert_equal "hello", var.name
    var.filters.first.tap do |filter|
      assert_equal "replace", filter.filtername
      assert_equal ["'foo'", "'bar'"], filter.filterargs
    end
    var.filters.last.tap do |filter|
      assert_equal "textileze", filter.filtername
    end
  end

  def test_symbol
    var = Variable.new("http://disney.com/logo.gif | image: 'med' ")
    assert_equal "http://disney.com/logo.gif", var.name
    var.filters.first.tap do |filter|
      assert_equal "image", filter.filtername
      assert_equal "'med'", filter.filterargs.first
    end
  end

  def test_string_single_quoted
    var = Variable.new(%( "hello" ))
    assert_equal "\"hello\"", var.name
  end

  def test_string_double_quoted
    var = Variable.new(%( 'hello' ))
    assert_equal "'hello'", var.name
  end

  def test_integer
    var = Variable.new(%( 1000 ))
    assert_equal "1000", var.name
  end

  def test_float
    var = Variable.new(%( 1000.01 ))
    assert_equal "1000.01", var.name
  end

  def test_string_with_special_chars
    var = Variable.new(%( 'hello! $!@.;"ddasd" ' ))
    assert_equal %('hello! $!@.;"ddasd" '), var.name
  end

  def test_string_dot
    var = Variable.new(%( test.test ))
    assert_equal "test.test", var.name
  end

  def test_filter_with_keyword_arguments
    var = Variable.new(%( hello | things: greeting: "world", farewell: 'goodbye'))
    assert_equal "hello", var.name
    var.filters.first.tap do |filter|
      assert_equal "things", filter.filtername
      assert_equal ["greeting: \"world\"", "farewell: 'goodbye'"], filter.filterargs
    end
  end
end

class VariableResolutionTest < Minitest::Test
  include Liquid

  def test_simple_variable
    template = Template.parse(%({{test}}))
    assert_equal "worked", template.render(Data.prepare({"test" => "worked"}))
    assert_equal "worked wonderfully", template.render(Data.prepare({"test" => "worked wonderfully"}))
  end

  def test_simple_with_whitespaces
    template = Template.parse(%(  {{ test }}  ))
    assert_equal "  worked  ", template.render(Data.prepare({"test" => "worked"}))
    assert_equal "  worked wonderfully  ", template.render(Data.prepare({"test" => "worked wonderfully"}))
  end

  def test_ignore_unknown
    template = Template.parse(%({{ test }}))
    assert_equal "", template.render
  end

  def test_hash_scoping
    template = Template.parse(%({{ test.test }}))
    assert_equal "worked", template.render(Data.prepare({"test" => {"test" => "worked"}}))
  end

  def test_preset_assigns
    template = Template.parse(%({{ test }}))
    template.assigns["test"] = "worked"
    assert_equal "worked", template.render
  end

  def test_reuse_parsed_template
    template = Template.parse(%({{ greeting }} {{ name }}))
    template.assigns["greeting"] = "Goodbye"
    assert_equal "Hello Tobi", template.render(Data.prepare({"greeting" => "Hello", "name" => "Tobi"}))
    assert_equal "Hello ", template.render(Data.prepare({"greeting" => "Hello", "unknown" => "Tobi"}))
    assert_equal "Hello Brian", template.render(Data.prepare({"greeting" => "Hello", "name" => "Brian"}))
    assert_equal(Data.prepare({"greeting" => "Goodbye"}), template.assigns)
    assert_equal "Goodbye Brian", template.render(Data.prepare({"name" => "Brian"}))
  end

  def test_assigns_not_polluted_from_template
    template = Template.parse(%({{ test }}{% assign test = 'bar' %}{{ test }}))
    template.assigns["test"] = "baz"
    assert_equal "bazbar", template.render
    assert_equal "bazbar", template.render
    assert_equal "foobar", template.render(Data.prepare({"test" => "foo"}))
    assert_equal "bazbar", template.render
  end

  # def test_hash_with_default_proc
  #   template = Template.parse(%|Hello {{ test }}|)
  #   assigns = Hash(String, Type).new { |h,k| raise "Unknown variable '#{k}'" }
  #   assigns["test"] = "Tobi"
  #   assert_equal "Hello Tobi", template.render!(assigns)
  #   assigns.delete("test")
  #   e = assert_raises(Error) {
  #     template.render!(assigns)
  #   }
  #   assert_equal "Unknown variable 'test'", e.message
  # end
end # VariableTest
