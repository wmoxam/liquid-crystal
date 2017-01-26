require "../test_helper"

class StrainerTest < Minitest::Test
  include Liquid

  class AccessScopeFilters < Liquid::Filter
    def public_filter
      "public"
    end

    private def private_filter
      "private"
    end
  end

  Strainer.global_filter(AccessScopeFilters)

  def test_strainer
    strainer = Strainer.create(nil)
    assert_equal 5, strainer.invoke("size", "input").raw
    assert_equal "public", strainer.invoke("public_filter").raw
  end

  def test_strainer_returns_nil_if_no_filter_method_found
    strainer = Strainer.create(nil)
    assert_nil strainer.invoke("private_filter").raw
    assert_nil strainer.invoke("undef_the_filter").raw
  end

  def test_strainer_returns_first_argument_if_no_method_and_arguments_given
    strainer = Strainer.create(nil)
    assert_equal "password", strainer.invoke("undef_the_method", "password").raw
  end

  def test_strainer_only_allows_methods_defined_in_filters
    strainer = Strainer.create(nil)
    assert_equal "1 + 1", strainer.invoke("instance_eval", "1 + 1").raw
    assert_equal "puts", strainer.invoke("__send__", "puts", "Hi Mom").raw
    assert_equal "has_method?", strainer.invoke("invoke", "has_method?", "invoke").raw
  end
end # StrainerTest
