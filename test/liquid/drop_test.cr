require "../test_helper"

class ContextDrop < Liquid::Drop
  def scopes
    @context.scopes.size
  end

  def scopes_as_array
    (1..@context.scopes.size).to_a
  end

  def loop_pos
    @context["forloop.index"]
  end

  def before_method(method)
    return @context[method]
  end
end

class ProductDrop < Liquid::Drop
  class TextDrop < Liquid::Drop
    def array
      ["text1", "text2"]
    end

    def text
      "text1"
    end
  end

  class CatchallDrop < Liquid::Drop
    def before_method(method)
      "method: #{method.to_s}"
    end
  end

  def texts
    TextDrop.new
  end

  def catchall
    CatchallDrop.new
  end

  def context
    ContextDrop.new
  end

  protected def callmenot
    "protected"
  end
end

class EnumerableDrop < Liquid::Drop
  def size
    3
  end

  def each
    yield 1
    yield 2
    yield 3
  end
end

class DropsTest < Minitest::Test
  def test_protected
    product = ProductDrop.new
    assert_nil product["callmenot"]
  end

  def test_drop_does_only_respond_to_whitelisted_methods
    product = ProductDrop.new
    assert_nil product["inspect"]
    assert_nil product["to_s"]
    assert_nil product["whatever"]
  end

  def test_text_drop
    product = ProductDrop.new
    text_drop = product["texts"]
    assert text_drop.is_a?(Liquid::Drop), "Didn't receive a drop"
    if text_drop.is_a?(Liquid::Drop)
      assert_equal "text1", text_drop["text"]
    end
  end

  def test_text_array_drop
    product = ProductDrop.new
    text_drop = product["texts"]
    assert text_drop.is_a?(Liquid::Drop), "Didn't receive a drop"
    if text_drop.is_a?(Liquid::Drop)
      assert_equal ["text1", "text2"], text_drop["array"]
    end
  end

  def test_unknown_method
    product = ProductDrop.new
    catchall = product["catchall"]
    assert catchall.is_a?(Liquid::Drop), "Didn't receive a drop"
    if catchall.is_a?(Liquid::Drop)
      assert_equal "method: unknown", catchall["unknown"]
    end
  end

  def test_integer_argument_drop
    product = ProductDrop.new
    catchall = product["catchall"]
    assert catchall.is_a?(Liquid::Drop), "Didn't receive a drop"
    if catchall.is_a?(Liquid::Drop)
      assert_equal "method: 8", catchall["8"]
    end
  end

  def test_protected
    product = ProductDrop.new
    assert_nil product["callmenot"]
  end

  def test_empty_string_value_access
    product = ProductDrop.new
    assert_nil product[""]
  end

  def test_nil_value_access
    product = ProductDrop.new
    assert_nil product[nil]
  end

  def test_product_drop
    tpl = Liquid::Template.parse(" ")
    assert_equal tpl.render({"product" => ProductDrop.new}), " "
  end

  def test_drops_respond_to_to_liquid
    assert_equal "text1", Liquid::Template.parse("{{ product.texts.text }}").render({"product" => ProductDrop.new})
    # assert_equal "text1", Liquid::Template.parse("{{ product | map: 'texts' | map: 'text' }}").render({"product" => ProductDrop.new})
  end

  def test_context_drop
    output = Liquid::Template.parse(" {{ context.bar }} ").render({"context" => ContextDrop.new, "bar" => "carrot"})
    assert_equal " carrot ", output
  end

  #
  #   def test_nested_context_drop
  #     output = Liquid::Template.parse( ' {{ product.context.foo }} '  ).render('product' => ProductDrop.new, 'foo' => "monkey")
  #     assert_equal ' monkey ', output
  #   end
  #
  #   def test_object_methods_not_allowed
  #     [:dup, :clone, :singleton_class, :eval, :class_eval, :inspect].each do |method|
  #       output = Liquid::Template.parse(" {{ product.#{method} }} ").render('product' => ProductDrop.new)
  #       assert_equal '  ', output
  #     end
  #   end
  #
  #   def test_scope
  #     assert_equal '1', Liquid::Template.parse( '{{ context.scopes }}'  ).render('context' => ContextDrop.new)
  #     assert_equal '2', Liquid::Template.parse( '{%for i in dummy%}{{ context.scopes }}{%endfor%}'  ).render('context' => ContextDrop.new, 'dummy' => [1])
  #     assert_equal '3', Liquid::Template.parse( '{%for i in dummy%}{%for i in dummy%}{{ context.scopes }}{%endfor%}{%endfor%}'  ).render('context' => ContextDrop.new, 'dummy' => [1])
  #   end
  #
  #   def test_scope_though_proc
  #     assert_equal '1', Liquid::Template.parse( '{{ s }}'  ).render('context' => ContextDrop.new, 's' => Proc.new{|c| c['context.scopes'] })
  #     assert_equal '2', Liquid::Template.parse( '{%for i in dummy%}{{ s }}{%endfor%}'  ).render('context' => ContextDrop.new, 's' => Proc.new{|c| c['context.scopes'] }, 'dummy' => [1])
  #     assert_equal '3', Liquid::Template.parse( '{%for i in dummy%}{%for i in dummy%}{{ s }}{%endfor%}{%endfor%}'  ).render('context' => ContextDrop.new, 's' => Proc.new{|c| c['context.scopes'] }, 'dummy' => [1])
  #   end
  #
  #   def test_scope_with_assigns
  #     assert_equal 'variable', Liquid::Template.parse( '{% assign a = "variable"%}{{a}}'  ).render('context' => ContextDrop.new)
  #     assert_equal 'variable', Liquid::Template.parse( '{% assign a = "variable"%}{%for i in dummy%}{{a}}{%endfor%}'  ).render('context' => ContextDrop.new, 'dummy' => [1])
  #     assert_equal 'test', Liquid::Template.parse( '{% assign header_gif = "test"%}{{header_gif}}'  ).render('context' => ContextDrop.new)
  #     assert_equal 'test', Liquid::Template.parse( "{% assign header_gif = 'test'%}{{header_gif}}"  ).render('context' => ContextDrop.new)
  #   end
  #
  #   def test_scope_from_tags
  #     assert_equal '1', Liquid::Template.parse( '{% for i in context.scopes_as_array %}{{i}}{% endfor %}'  ).render('context' => ContextDrop.new, 'dummy' => [1])
  #     assert_equal '12', Liquid::Template.parse( '{%for a in dummy%}{% for i in context.scopes_as_array %}{{i}}{% endfor %}{% endfor %}'  ).render('context' => ContextDrop.new, 'dummy' => [1])
  #     assert_equal '123', Liquid::Template.parse( '{%for a in dummy%}{%for a in dummy%}{% for i in context.scopes_as_array %}{{i}}{% endfor %}{% endfor %}{% endfor %}'  ).render('context' => ContextDrop.new, 'dummy' => [1])
  #   end
  #
  #   def test_access_context_from_drop
  #     assert_equal '123', Liquid::Template.parse( '{%for a in dummy%}{{ context.loop_pos }}{% endfor %}'  ).render('context' => ContextDrop.new, 'dummy' => [1,2,3])
  #   end
  #
  #   def test_enumerable_drop
  #     assert_equal '123', Liquid::Template.parse( '{% for c in collection %}{{c}}{% endfor %}').render('collection' => EnumerableDrop.new)
  #   end

  def test_enumerable_drop_size
    tpl = Liquid::Template.parse("{{collection.size}}")
    assert_equal "3", tpl.render({"collection" => EnumerableDrop.new})
  end
end # DropsTest
