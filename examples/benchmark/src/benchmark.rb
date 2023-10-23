require 'benchmark/ips'
require "liquid"

liquid_template = <<-END
{% for product in products %}
  <div class='product_brick'>
    <div class='container'>
      <div class='element'>
        <img src='images/{{ product.image }}' class='product_miniature' />
      </div>
      <div class='element description'>
        <a href={{ product.url }} class='product_name block bold'>
          {{ product.name }}
        </a>
      </div>
    </div>
  </div>
{% endfor %}


END

data = {
  "products" => 100.times.map do |n|
    { "image" => "foo-#{rand 100}.png", "url" => "http://bar-#{rand 100}.com", "name" => "FOO #{"a" * rand(100)}" }
  end.to_a
}

def render_liquid(template, data)
 Liquid::Template.parse(template).render(data)
end

liquid_template_pre = Liquid::Template.parse(liquid_template)

def render_liquid_pre(tmpl, data)
 tmpl.render(data)
end

Benchmark.ips do |x|
  x.report("render_liquid") { render_liquid(liquid_template, data) }
  x.report("render_liquid_pre") { render_liquid_pre(liquid_template_pre, data) }
  x.compare!
end
