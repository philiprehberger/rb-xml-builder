# philiprehberger-xml_builder

[![Tests](https://github.com/philiprehberger/rb-xml-builder/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-xml-builder/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-xml_builder.svg)](https://rubygems.org/gems/philiprehberger-xml_builder)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-xml-builder)](https://github.com/philiprehberger/rb-xml-builder/commits/main)

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

### Basic Elements

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

### XML Namespaces

Register namespace prefixes and create namespace-aware elements:

```ruby
xml = Philiprehberger::XmlBuilder.build do |doc|
  doc.namespace(:soap, "http://schemas.xmlsoap.org/soap/envelope/")
  doc.namespace(:wsse, "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd")

  doc.namespace_tag(:soap, :Envelope) do
    doc.namespace_tag(:soap, :Header) do
      doc.namespace_tag(:wsse, :Security)
    end
    doc.namespace_tag(:soap, :Body)
  end
end
```

You can also use string tag names directly:

```ruby
xml = Philiprehberger::XmlBuilder.build do |doc|
  doc.tag("soap:Envelope", "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/") do
    doc.tag("soap:Body")
  end
end
```

### SOAP Envelope Builder

Build SOAP 1.1 or 1.2 envelopes with a convenience DSL:

```ruby
xml = Philiprehberger::XmlBuilder.build do |doc|
  doc.soap_envelope(version: "1.1") do |header, body|
    header << ->(d) { d.tag("auth") { d.text("token123") } }
    body << ->(d) { d.tag("GetPrice") { d.text("Widget") } }
  end
end
```

Or use the top-level shortcut:

```ruby
xml = Philiprehberger::XmlBuilder.build_soap(soap_version: "1.2") do |header, body|
  body << ->(d) { d.tag("GetStockPrice") { d.tag("Symbol") { d.text("AAPL") } } }
end
```

### XML Fragment Composition

Combine separately built document fragments:

```ruby
# Build fragments independently
header = Philiprehberger::XmlBuilder::Document.new
header.tag(:title) { header.text("My Document") }

body = Philiprehberger::XmlBuilder::Document.new
body.tag(:paragraph) { body.text("Hello world") }

# Compose into a single document
xml = Philiprehberger::XmlBuilder.build do |doc|
  doc.tag(:document) do
    doc.tag(:header) { doc.append(header) }
    doc.tag(:body) { doc.append(body) }
  end
end
```

Insert raw XML fragment strings:

```ruby
xml = Philiprehberger::XmlBuilder.build do |doc|
  doc.tag(:root) do
    doc.insert_fragment('<existing>data</existing>')
  end
end
```

## API

### `Philiprehberger::XmlBuilder`

| Method | Description |
|--------|-------------|
| `.build(encoding: "UTF-8", version: "1.0") { \|doc\| ... }` | Build an XML document and return the string |
| `.build_soap(soap_version: "1.1", encoding: "UTF-8", version: "1.0") { \|header, body\| ... }` | Build a SOAP envelope document |

### `Document`

| Method | Description |
|--------|-------------|
| `#tag(name, attributes = {}) { ... }` | Add an element with optional attributes and children |
| `#text(content)` | Add escaped text content |
| `#cdata(content)` | Add a CDATA section |
| `#comment(text)` | Add an XML comment |
| `#processing_instruction(target, content)` | Add a processing instruction |
| `#raw(string)` | Add raw unescaped XML |
| `#namespace(prefix, uri)` | Register an XML namespace prefix and URI |
| `#namespace_tag(prefix, name, attributes = {}) { ... }` | Add a namespace-prefixed element with auto xmlns |
| `#soap_envelope(version: "1.1") { \|header, body\| ... }` | Build a SOAP envelope with Header and Body |
| `#append(other_document)` | Append children from another Document |
| `#insert_fragment(xml_string)` | Insert a raw XML fragment string |
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

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-xml-builder)

🐛 [Report issues](https://github.com/philiprehberger/rb-xml-builder/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-xml-builder/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
