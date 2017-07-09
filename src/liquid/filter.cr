module Liquid
  class FilterNotInvokable; end

  class Filter
    def initialize(@context : Nil | Context)
    end

    macro def invoke(method_name, *args) : Object
      {% begin %}
      case method_name
      when nil, ""
        nil
      {% for method in @type.methods %}
        {% if !method.name.ends_with?("=") &&
            method.visibility == :public &&
            !["invoke",
              "[]",
              "has_key?",
              "each",
              "inspect"].any? { |meth| meth == method.name } %}
      when {{method.name.stringify}}
        {% for i in (0..(method.args.size - 1)) %}
          default{{i}} = {% if method.args[i].default_value %}{{method.args[i].default_value}}{% else %}nil{% end %}
          arg{{i}} = if args.nil?
            default{{i}}
          else
            args.at({{i}}) { default{{i}} }{% if method.args[i].restriction %}.as {{method.args[i].restriction}}{% end %}
          end
        {% end %}

        self.{{method.name}}({% for i in (0..(method.args.size - 1)) %}arg{{i}}{% if i < (method.args.size - 1) %}, {% end %}{% end %})
        {% end %}
      {% end %}
      else
        Liquid::FilterNotInvokable.new
      end
      {% end %}
    end
  end
end
