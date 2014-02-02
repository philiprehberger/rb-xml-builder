# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::XmlBuilder do
  it 'has a version number' do
    expect(Philiprehberger::XmlBuilder::VERSION).not_to be_nil
  end

  describe '.build' do
    it 'produces an XML declaration' do
      xml = described_class.build { |_doc| }
      expect(xml).to start_with('<?xml version="1.0" encoding="UTF-8"?>')
    end

    it 'supports custom encoding and version' do
      xml = described_class.build(encoding: 'ISO-8859-1', version: '1.1') { |_doc| }
      expect(xml).to start_with('<?xml version="1.1" encoding="ISO-8859-1"?>')
    end
  end

  describe 'simple element' do
    it 'creates a self-closing element with no children' do
      xml = described_class.build do |doc|
        doc.tag(:item)
      end
      expect(xml).to include('<item />')
    end

    it 'creates an element with text content' do
      xml = described_class.build do |doc|
        doc.tag(:greeting) { doc.text('hello') }
      end
      expect(xml).to include('<greeting>hello</greeting>')
    end
  end

  describe 'nested elements' do
    it 'nests elements inside a parent' do
      xml = described_class.build do |doc|
        doc.tag(:root) do
          doc.tag(:child) { doc.text('value') }
        end
      end
      expect(xml).to include('<root><child>value</child></root>')
    end

    it 'supports multiple levels of nesting' do
      xml = described_class.build do |doc|
        doc.tag(:a) do
          doc.tag(:b) do
            doc.tag(:c) { doc.text('deep') }
          end
        end
      end
      expect(xml).to include('<a><b><c>deep</c></b></a>')
    end
  end

  describe 'attributes' do
    it 'adds attributes to an element' do
      xml = described_class.build do |doc|
        doc.tag(:link, href: 'https://example.com', rel: 'stylesheet')
      end
      expect(xml).to include('<link href="https://example.com" rel="stylesheet" />')
    end

    it 'escapes attribute values' do
      xml = described_class.build do |doc|
        doc.tag(:input, value: 'say "hello" & goodbye')
      end
      expect(xml).to include('value="say &quot;hello&quot; &amp; goodbye"')
    end
  end

  describe 'text escaping' do
    it 'escapes special characters in text' do
      xml = described_class.build do |doc|
        doc.tag(:data) { doc.text('<script>alert("xss")</script>') }
      end
      expect(xml).to include('&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;')
    end

    it 'escapes ampersands' do
      xml = described_class.build do |doc|
        doc.tag(:data) { doc.text('AT&T') }
      end
      expect(xml).to include('<data>AT&amp;T</data>')
    end

    it 'escapes apostrophes' do
      xml = described_class.build do |doc|
        doc.tag(:data) { doc.text("it's") }
      end
      expect(xml).to include('<data>it&apos;s</data>')
    end
  end

  describe 'CDATA' do
    it 'adds a CDATA section' do
      xml = described_class.build do |doc|
        doc.tag(:script) { doc.cdata('var x = 1 < 2 && true;') }
      end
      expect(xml).to include('<script><![CDATA[var x = 1 < 2 && true;]]></script>')
    end
  end

  describe 'comments' do
    it 'adds an XML comment' do
      xml = described_class.build do |doc|
        doc.comment('This is a comment')
        doc.tag(:root)
      end
      expect(xml).to include('<!-- This is a comment -->')
    end

    it 'adds a comment inside an element' do
      xml = described_class.build do |doc|
        doc.tag(:root) do
          doc.comment('inner comment')
          doc.tag(:child)
        end
      end
      expect(xml).to include('<!-- inner comment -->')
    end
  end

  describe 'processing instructions' do
    it 'adds a processing instruction' do
      xml = described_class.build do |doc|
        doc.processing_instruction('xml-stylesheet', 'type="text/xsl" href="style.xsl"')
        doc.tag(:root)
      end
      expect(xml).to include('<?xml-stylesheet type="text/xsl" href="style.xsl"?>')
    end
  end

  describe 'raw content' do
    it 'inserts raw XML without escaping' do
      xml = described_class.build do |doc|
        doc.tag(:root) { doc.raw('<already>escaped</already>') }
      end
      expect(xml).to include('<root><already>escaped</already></root>')
    end
  end

  describe 'method_missing DSL' do
    it 'creates elements via method names' do
      xml = described_class.build do |doc|
        doc.person(name: 'John') do
          doc.age('30')
          doc.email('john@example.com')
        end
      end
      expect(xml).to include('<person name="John">')
      expect(xml).to include('<age>30</age>')
      expect(xml).to include('<email>john@example.com</email>')
    end

    it 'creates self-closing elements via method names' do
      xml = described_class.build(&:br)
      expect(xml).to include('<br />')
    end

    it 'creates elements with text content via method names' do
      xml = described_class.build do |doc|
        doc.title('Hello World')
      end
      expect(xml).to include('<title>Hello World</title>')
    end

    it 'creates elements with text and attributes' do
      xml = described_class.build do |doc|
        doc.link('Click', href: '/page')
      end
      expect(xml).to include('<link href="/page">Click</link>')
    end
  end

  describe 'indentation' do
    it 'renders with indentation via to_xml' do
      doc = Philiprehberger::XmlBuilder::Document.new
      doc.tag(:root) do
        doc.tag(:child) { doc.text('value') }
      end
      result = doc.to_xml(indent: 2)

      expect(result).to include('<?xml')
      expect(result).to include('  <child>value</child>')
      expect(result).to include('<root>')
      expect(result).to include('</root>')
    end

    it 'renders compact output by default' do
      xml = described_class.build do |doc|
        doc.tag(:root) do
          doc.tag(:child) { doc.text('value') }
        end
      end
      expect(xml).not_to include("\n  ")
      expect(xml).to include('<root><child>value</child></root>')
    end
  end

  describe Philiprehberger::XmlBuilder::Escaper do
    it 'escapes all five XML entities' do
      result = described_class.escape('&<>"\' test')
      expect(result).to eq('&amp;&lt;&gt;&quot;&apos; test')
    end

    it 'returns the same string when no escaping is needed' do
      result = described_class.escape('plain text')
      expect(result).to eq('plain text')
    end

    it 'handles empty strings' do
      result = described_class.escape('')
      expect(result).to eq('')
    end
  end
end
