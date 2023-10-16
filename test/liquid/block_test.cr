require "../test_helper"

class BlockTest < Minitest::Test
  include Liquid

  def test_blankspace
    template = Liquid::Template.parse("  ")
    assert_equal ["  "], template.root.try &.nodelist
  end

  def test_variable_beginning
    template = Liquid::Template.parse("{{funk}}  ")
    assert_equal 2, template.root.try(&.nodelist).try(&.size)
    assert_equal Variable, template.root && template.root.not_nil!.nodelist[0]?.try(&.class)
    assert_equal String, template.root && template.root.not_nil!.nodelist[1]?.try(&.class)
  end

  def test_variable_end
    template = Liquid::Template.parse("  {{funk}}")
    assert_equal 2, template.root.try(&.nodelist).try(&.size)
    assert_equal String, template.root && template.root.not_nil!.nodelist[0]?.try(&.class)
    assert_equal Variable, template.root && template.root.not_nil!.nodelist[1]?.try(&.class)
  end

  def test_variable_middle
    template = Liquid::Template.parse("  {{funk}}  ")
    assert_equal 3, template.root.try(&.nodelist).try(&.size)
    assert_equal String, template.root && template.root.not_nil!.nodelist[0]?.try(&.class)
    assert_equal Variable, template.root && template.root.not_nil!.nodelist[1]?.try(&.class)
    assert_equal String, template.root && template.root.not_nil!.nodelist[2]?.try(&.class)
  end

  def test_variable_many_embedded_fragments
    template = Liquid::Template.parse("  {{funk}} {{so}} {{brother}} ")
    assert_equal 7, template.root.try(&.nodelist).try(&.size)
    assert_equal [String, Variable, String, Variable, String, Variable, String],
      block_types(template.root.try(&.nodelist))
  end

  def test_with_block
    template = Liquid::Template.parse("  {% comment %} {% endcomment %} ")
    assert_equal [String, Comment, String], block_types(template.root.try(&.nodelist))
    assert_equal 3, template.root.try(&.nodelist).try(&.size)
  end

  def test_with_custom_tag
    Liquid::Template.register_tag("testtag", Block)

    template = Liquid::Template.parse("{% testtag %} {% endtesttag %}")
    assert_equal template.render, " "
  end

  private def block_types(nodelist)
    return [] of Nil.class if nodelist.nil?
    nodelist.not_nil!.map { |node| node.class }
  end
end # VariableTest
