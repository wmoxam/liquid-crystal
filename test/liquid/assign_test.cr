require "../test_helper"

class AssignTest < Minitest::Test
  include Liquid

  def test_assigned_variable
    assert_template_result(".foo.",
      "{% assign foo = values %}.{{ foo[0] }}.",
      Data.prepare({"values" => %w{foo bar baz}}))

    assert_template_result(".bar.",
      "{% assign foo = values %}.{{ foo[1] }}.",
      Data.prepare({"values" => %w{foo bar baz}}))
  end

  def test_assign_with_filter
    assert_template_result(".bar.",
      "{% assign foo = values | split: \",\" %}.{{ foo[1] }}.",
      Data.prepare({"values" => "foo,bar,baz"}))
  end
end # AssignTest
