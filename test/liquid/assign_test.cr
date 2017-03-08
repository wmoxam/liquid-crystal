require "../test_helper"

class AssignTest < Minitest::Test
  include Liquid
  include Liquid::Data

  def test_assigned_variable
    assert_template_result(".foo.",
                           "{% assign foo = values %}.{{ foo[0] }}.",
                           _h({"values" => %w{foo bar baz}}))

    assert_template_result(".bar.",
                           "{% assign foo = values %}.{{ foo[1] }}.",
                           _h({"values" => %w{foo bar baz}}))
  end

  def test_assign_with_filter
    assert_template_result(".bar.",
                           "{% assign foo = values | split: \",\" %}.{{ foo[1] }}.",
                           _h({"values" => "foo,bar,baz"}))
  end
end # AssignTest
