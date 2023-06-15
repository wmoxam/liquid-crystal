require "../../test_helper"

class TestFileSystem < Liquid::FileSystem
  def read_template_file(template_path, context)
    case template_path
    when "product"
      "Product: {{ product.title }} "
    when "locale_variables"
      "Locale: {{echo1}} {{echo2}}"
    when "variant"
      "Variant: {{ variant.title }}"
    when "nested_template"
      "{% include 'header' %} {% include 'body' %} {% include 'footer' %}"
    when "body"
      "body {% include 'body_detail' %}"
    when "nested_product_template"
      "Product: {{ nested_product_template.title }} {%include 'details'%} "
    when "recursively_nested_template"
      "-{% include 'recursively_nested_template' %}"
    when "pick_a_source"
      "from TestFileSystem"
    else
      template_path
    end
  end
end

class OtherFileSystem < Liquid::FileSystem
  def read_template_file(template_path, context)
    "from OtherFileSystem"
  end
end

class InfiniteFileSystem < Liquid::FileSystem
  def read_template_file(template_path, context)
    "-{% include 'loop' %}"
  end
end

class IncludeTagTest < Minitest::Test
  include Liquid

  def setup
    Liquid::Template.file_system = TestFileSystem.new
  end

  def test_include_tag_looks_for_file_system_in_registers_first
    fs = OtherFileSystem.new.as Type
    assert_equal "from OtherFileSystem",
      Template.parse("{% include 'pick_a_source' %}").render({} of String => Type, {:file_system => fs})
  end

  def test_include_tag_with
    assert_equal "Product: Draft 151cm ",
      Template.parse("{% include 'product' with products[0] %}").render(Data.prepare({"products" => [{"title" => "Draft 151cm"}, {"title" => "Element 155cm"}]}))
  end

  def test_include_tag_with_default_name
    assert_equal "Product: Draft 151cm ",
      Template.parse("{% include 'product' %}").render(Data.prepare({"product" => {"title" => "Draft 151cm"}}))
  end

  def test_include_tag_for
    assert_equal "Product: Draft 151cm Product: Element 155cm ",
      Template.parse("{% include 'product' for products %}").render(Data.prepare({"products" => [{"title" => "Draft 151cm"}, {"title" => "Element 155cm"}]}))
  end

  def test_include_tag_with_local_variables
    assert_equal "Locale: test123 ",
      Template.parse("{% include 'locale_variables' echo1: 'test123' %}").render
  end

  def test_include_tag_with_multiple_local_variables
    assert_equal "Locale: test123 test321",
      Template.parse("{% include 'locale_variables' echo1: 'test123', echo2: 'test321' %}").render
  end

  def test_include_tag_with_multiple_local_variables_from_context
    assert_equal "Locale: test123 test321",
      Template.parse("{% include 'locale_variables' echo1: echo1, echo2: more_echos.echo2 %}").render(Data.prepare({"echo1" => "test123", "more_echos" => {"echo2" => "test321"}}))
  end

  def test_nested_include_tag
    assert_equal "body body_detail",
      Template.parse("{% include 'body' %}").render

    assert_equal "header body body_detail footer",
      Template.parse("{% include 'nested_template' %}").render
  end

  def test_nested_include_with_variable
    assert_equal "Product: Draft 151cm details ",
      Template.parse("{% include 'nested_product_template' with product %}").render(Data.prepare({"product" => {"title" => "Draft 151cm"}}))

    assert_equal "Product: Draft 151cm details Product: Element 155cm details ",
      Template.parse("{% include 'nested_product_template' for products %}").render(Data.prepare({"products" => [{"title" => "Draft 151cm"}, {"title" => "Element 155cm"}]}))
  end

  def test_recursively_included_template_does_not_produce_endless_loop
    Liquid::Template.file_system = InfiniteFileSystem.new

    assert_raises(Liquid::StackLevelError) do
      Template.parse("{% include 'loop' %}").render!
    end
  end

  def test_dynamically_choosen_template
    assert_equal "Test123", Template.parse("{% include template %}").render(Data.prepare({"template" => "Test123"}))
    assert_equal "Test321", Template.parse("{% include template %}").render(Data.prepare({"template" => "Test321"}))

    assert_equal "Product: Draft 151cm ", Template.parse("{% include template for product %}").render(Data.prepare({"template" => "product", "product" => {"title" => "Draft 151cm"}}))
  end
end # IncludeTagTest
