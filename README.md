# philiprehberger-xml_builder

[![Tests](https://github.com/philiprehberger/rb-xml-builder/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-xml-builder/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-xml_builder.svg)](https://rubygems.org/gems/philiprehberger-xml_builder)
[![License](https://img.shields.io/github/license/philiprehberger/rb-xml-builder)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

Lightweight XML builder DSL without Nokogiri dependency

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-xml_builder"
```

Or install directly:

```bash
gem install philiprehberger-xml_builder
```

## Usage

```ruby
require "philiprehberger/xml_builder"

xml = Philiprehberger::XmlBuilder.build do |doc|
  doc.tag(:root) do
    doc.tag(:item, id: "1") { doc.text("Hello") }
  end
end

puts xml
# <?xml version="1.0" encoding="UTF-8"?><root><item id="1">Hello</item></root>
```

### Method Missing DSL

Use method names directly as tag names for a cleaner syntax:

```ruby
xml = Philiprehberger::XmlBuilder.build do |doc|
  doc.person(name: "John") do
    doc.age("30")
    doc.email("john@example.com")
  end
end
# <person name="John"><age>30</age><email>john@example.com</email></person>
```

### CDATA and Comments

```ruby
xml = Philiprehberger::XmlBuilder.build do |doc|
  doc.tag(:root) do
    doc.comment("Generated XML")
    doc.tag(:script) { doc.cdata('var x = 1 < 2;') }
  end
end
```

### Processing Instructions

```ruby
xml = Philiprehberger::XmlBuilder.build do |doc|
  doc.processing_instruction("xml-stylesheet", 'type="text/xsl" href="style.xsl"')
  doc.tag(:root) { doc.text("content") }
end
```

### Pretty Printing

```ruby
doc = Philiprehberger::XmlBuilder::Document.new
doc.tag(:root) do
  doc.tag(:child) { doc.text("value") }
end

puts doc.to_xml(indent: 2)
# <?xml version="1.0" encoding="UTF-8"?>
# <root>
#   <child>value</child>
# </root>
```

### Raw XML

```ruby
xml = Philiprehberger::XmlBuilder.build do |doc|
  doc.tag(:root) { doc.raw("<pre>formatted</pre>") }
end
```

## API

### `Philiprehberger::XmlBuilder`

| Method | Description |
|--------|-------------|
| `.build(encoding: "UTF-8", version: "1.0") { \|doc\| ... }` | Build an XML document and return the string |

### `Document`

| Method | Description |
|--------|-------------|
| `#tag(name, attributes = {}) { ... }` | Add an element with optional attributes and children |
| `#text(content)` | Add escaped text content |
| `#cdata(content)` | Add a CDATA section |
| `#comment(text)` | Add an XML comment |
| `#processing_instruction(target, content)` | Add a processing instruction |
| `#raw(string)` | Add raw unescaped XML |
| `#to_s` | Render compact XML string |
| `#to_xml(indent: nil)` | Render XML with optional indentation |

### `Escaper`

| Method | Description |
|--------|-------------|
| `.escape(text)` | Escape XML entities (&, <, >, ", ') |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

[MIT](LICENSE)
