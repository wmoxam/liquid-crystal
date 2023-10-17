module Liquid
  # A drop in liquid is a class which allows you to export DOM like things to
  # liquid.
  # Methods of drops are callable.
  # The main use for liquid drops is to implement lazy loaded objects.
  # If you would like to make data available to the web designers which you don't
  # want loaded unless needed then a drop is a great way to do that.
  #
  # Example:
  #
  #   class ProductDrop < Liquid::Drop
  #     def top_sales
  #       Shop.current.products.find(:all, :order => 'sales', :limit => 10 )
  #     end
  #   end
  #
  #   tmpl = Liquid::Template.parse( ' {% for product in product.top_sales %} {{ product.name }} {%endfor%} '  )
  #   tmpl.render('product' => ProductDrop.new ) # will invoke top_sales query.
  #
  # Your drop can either implement the methods sans any parameters or implement
  # the before_method(name) method which is a catch all.
  class Drop
    property context : Context

    def initialize(context = Context.new)
      @context = context
    end

    # Catch all for the method
    def before_method(method)
      nil
    end

    # called by liquid to invoke a drop
    # TODO: explictly defining forbidden methods shouldn't be needed
    # the macro type methods should only return methods defined in that class,
    # not any inherited methods
    def invoke_drop(method_or_key) : Liquid::Type
      value = nil
      {% begin %}
      value = case method_or_key
      when nil, ""
        nil
      {% for method in @type.methods %}
        {% if !method.name.ends_with?("=") &&
                method.visibility == :public &&
                !["before_method",
                  "invoke_drop",
                  "[]",
                  "has_key?",
                  "each",
                  "inspect"].any? { |meth| meth == method.name } %}
      when {{method.name.stringify}}
        self.{{method.name}}()
        {% end %}
      {% end %}
      else
        before_method(method_or_key)
      end
      {% end %}

      if value.is_a?(Array) || value.is_a?(Hash)
        Liquid::Data.prepare(value)
      else
        value
      end
    end

    def [](method_or_key)
      invoke_drop(method_or_key)
    end

    def has_key?(name)
      true
    end

    def to_liquid
      self
    end
  end
end
