require "../test_helper"

class ErrorDrop < Liquid::Drop
  def standard_error
    raise Liquid::StandardError.new "standard error"
  end

  def argument_error
    raise Liquid::ArgumentError.new "argument error"
  end

  def syntax_error
    raise Liquid::SyntaxError.new "syntax error"
  end

  def exception
    raise Exception.new "exception"
  end
end

class ErrorHandlingTest < Minitest::Test
  include Liquid

  def test_exceptions
    drop = ErrorDrop.new
    assert_raises Liquid::StandardError do
      drop["standard_error"]
    end
  end

  def test_standard_error
    template = Liquid::Template.parse(" {{ errors.standard_error }} ")
    assert_equal " Liquid error: standard error ", template.render({"errors" => ErrorDrop.new})

    assert_equal 1, template.errors.size
    assert_equal StandardError, template.errors.first.class
  end

  #
  # def test_syntax
  #
  #   assert_nothing_raised do
  #
  #     template = Liquid::Template.parse( ' {{ errors.syntax_error }} '  )
  #     assert_equal ' Liquid syntax error: syntax error ', template.render('errors' => ErrorDrop.new)
  #
  #     assert_equal 1, template.errors.size
  #     assert_equal SyntaxError, template.errors.first.class
  #
  #   end
  # end
  #
  # def test_argument
  #   assert_nothing_raised do
  #
  #     template = Liquid::Template.parse( ' {{ errors.argument_error }} '  )
  #     assert_equal ' Liquid error: argument error ', template.render('errors' => ErrorDrop.new)
  #
  #     assert_equal 1, template.errors.size
  #     assert_equal ArgumentError, template.errors.first.class
  #   end
  # end

  def test_missing_endtag_parse_time_error
    assert_raises(Liquid::SyntaxError) do
      template = Liquid::Template.parse(" {% for a in b %} ... ")
    end
  end

  # def test_unrecognized_operator
  #   assert_nothing_raised do
  #     template = Liquid::Template.parse(' {% if 1 =! 2 %}ok{% endif %} ')
  #     assert_equal ' Liquid error: Unknown operator =! ', template.render
  #     assert_equal 1, template.errors.size
  #     assert_equal Liquid::ArgumentError, template.errors.first.class
  #   end
  # end

  # Liquid should not catch Exceptions that are not subclasses of StandardError, like Interrupt and NoMemoryError
  # def test_exceptions_propagate
  #   assert_raises Exception do
  #     template = Liquid::Template.parse(" {{ errors.exception }} ")
  #     template.render({"errors" => ErrorDrop.new})
  #   end
  # end
end # ErrorHandlingTest
