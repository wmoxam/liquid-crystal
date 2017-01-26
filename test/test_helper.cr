require "minitest/autorun"

require "../src/liquid.cr"

module Minitest
  class Test
    def assert_template_result(expected, template, assigns = {} of String => Liquid::Type, message = nil)
      assert_equal expected, Liquid::Template.parse(template).render(assigns)
    end

    #      def assert_template_result_matches(expected, template, assigns = {}, message = nil)
    #        return assert_template_result(expected, template, assigns, message) unless expected.is_a? Regexp
    #
    #        assert_match expected, Template.parse(template).render(assigns)
    #      end
  end
end
