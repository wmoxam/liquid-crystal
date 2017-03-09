require "../test_helper"

class MoneyFilter < Liquid::Filter
  def money(input)
    " %d$ " % input.to_s
  end

  def money_with_underscore(input)
    " %d$ " % input.to_s
  end
end

class CanadianMoneyFilter < Liquid::Filter
  def money(input)
    " %d$ CAD " % input.to_s
  end
end

# class SubstituteFilter < Liquid::Filter
#   def substitute(input, params={} of String => Filter)
#     input.to_s.gsub(/%\{(\w+)\}/) { |match| params[$1] }
#   end
# end

class FiltersTest < Minitest::Test
  include Liquid
  include Liquid::Data

  def initialize(r)
    @context = Context.new
    super
  end

  def test_local_filter
    @context["var"] = 1000
    @context.add_filters(MoneyFilter)

    assert_equal " 1000$ ", Variable.new("var | money").render(@context).as(Any).raw
  end

  def test_underscore_in_filter_name
    @context["var"] = 1000
    @context.add_filters(MoneyFilter)
    assert_equal " 1000$ ", Variable.new("var | money_with_underscore").render(@context).as(Any).raw
  end

  def test_second_filter_overwrites_first
    @context["var"] = 1000
    @context.add_filters(MoneyFilter)
    @context.add_filters(CanadianMoneyFilter)

    assert_equal " 1000$ CAD ", Variable.new("var | money").render(@context).as(Any).raw
  end

  def test_size
    @context["var"] = "abcd"
    @context.add_filters(MoneyFilter)

    assert_equal 4, Variable.new("var | size").render(@context).as(Any).raw
  end

  def test_join
    @context["var"] = _a([1,2,3,4])

    assert_equal "1 2 3 4", Variable.new("var | join").render(@context).as(Any).raw
  end

  # def test_sort
  #   @context["value"] = 3
  #   @context["numbers"] = _a([2,1,4,3])
  #   @context["words"] = _a(["expected", "as", "alphabetic"])
  #   @context["arrays"] = _a([["flattened"], ["are"]])
  #
  #   assert_equal _a([1,2,3,4]), Variable.new("numbers | sort").render(@context).as(Any).raw
  #   assert_equal _a(["alphabetic", "as", "expected"]), Variable.new("words | sort").render(@context).as(Any).raw
  #   assert_equal _a([3]), Variable.new("value | sort").render(@context).as(Any).raw
  #   assert_equal _a(["are", "flattened"]), Variable.new("arrays | sort").render(@context).as(Any).raw
  # end

  def test_strip_html
    @context["var"] = "<b>bla blub</a>"

    assert_equal "bla blub", Variable.new("var | strip_html").render(@context).as(Any).raw
  end

  def test_strip_html_ignore_comments_with_html
    @context["var"] = "<!-- split and some <ul> tag --><b>bla blub</a>"

    assert_equal "bla blub", Variable.new("var | strip_html").render(@context).as(Any).raw
  end

  def test_capitalize
    @context["var"] = "blub"

    assert_equal "Blub", Variable.new("var | capitalize").render(@context).as(Any).raw
  end

  def test_nonexistent_filter_is_ignored
    @context["var"] = 1000

    assert_equal 1000, Variable.new("var | xyzzy").render(@context).as(Any).raw
  end

#  def test_filter_with_keyword_arguments
#    @context["surname"] = "john"
#    @context.add_filters(SubstituteFilter)
#    output = Variable.new(%[ 'hello %{first_name}, %{last_name}' | substitute: first_name: surname, last_name: 'doe' ]).render(@context)
#    assert_equal "hello john, doe", output
#  end
end

class FiltersInTemplate < Minitest::Test
  include Liquid

  def test_local_global
    Template.register_filter(MoneyFilter)

    assert_equal " 1000$ ", Template.parse("{{1000 | money}}").render()
    # assert_equal " 1000$ CAD ", Template.parse("{{1000 | money}}").render(({} of String => Type), CanadianMoneyFilter)
    assert_equal " 1000$ CAD ", Template.parse("{{1000 | money}}").render(({} of String => Type), [CanadianMoneyFilter])
  end
end # FiltersTest
