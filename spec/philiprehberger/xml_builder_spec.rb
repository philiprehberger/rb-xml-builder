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

    it 'raises an error when content contains ]]>' do
      expect do
        described_class.build do |doc|
          doc.tag(:script) { doc.cdata('invalid ]]> content') }
        end
      end.to raise_error(Philiprehberger::XmlBuilder::Error, /CDATA content must not contain/)
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

    it 'raises an error when text contains --' do
      expect do
        described_class.build do |doc|
          doc.comment('invalid -- comment')
        end
      end.to raise_error(Philiprehberger::XmlBuilder::Error, /Comment text must not contain/)
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

  describe 'declaration option' do
    it 'omits the XML declaration when declaration: false' do
      xml = described_class.build(declaration: false) do |doc|
        doc.tag(:root) { doc.text('hello') }
      end
      expect(xml).not_to include('<?xml')
      expect(xml).to eq('<root>hello</root>')
    end

    it 'omits the declaration via Document.new' do
      doc = Philiprehberger::XmlBuilder::Document.new(declaration: false)
      doc.tag(:item) { doc.text('value') }
      expect(doc.to_xml).not_to include('<?xml')
      expect(doc.to_xml).to eq('<item>value</item>')
    end

    it 'omits the declaration with indentation' do
      doc = Philiprehberger::XmlBuilder::Document.new(declaration: false)
      doc.tag(:root) do
        doc.tag(:child) { doc.text('value') }
      end
      result = doc.to_xml(indent: 2)
      expect(result).not_to include('<?xml')
      expect(result).to start_with('<root>')
    end

    it 'includes the declaration by default' do
      xml = described_class.build do |doc|
        doc.tag(:root)
      end
      expect(xml).to start_with('<?xml version="1.0" encoding="UTF-8"?>')
    end
  end

  describe 'XML namespace support' do
    it 'creates a namespace-prefixed element with xmlns declaration' do
      xml = described_class.build do |doc|
        doc.namespace(:soap, 'http://schemas.xmlsoap.org/soap/envelope/')
        doc.namespace_tag(:soap, :Envelope) do
          doc.namespace_tag(:soap, :Body)
        end
      end
      expect(xml).to include('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">')
      expect(xml).to include('<soap:Body')
    end

    it 'supports multiple namespace prefixes' do
      xml = described_class.build do |doc|
        doc.namespace(:soap, 'http://schemas.xmlsoap.org/soap/envelope/')
        doc.namespace(:wsse, 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd')
        doc.namespace_tag(:soap, :Envelope) do
          doc.namespace_tag(:wsse, :Security)
        end
      end
      expect(xml).to include('xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"')
      expect(xml).to include('xmlns:wsse=')
      expect(xml).to include('<wsse:Security')
    end

    it 'allows additional attributes on namespace tags' do
      xml = described_class.build do |doc|
        doc.namespace(:ns, 'http://example.com/ns')
        doc.namespace_tag(:ns, :item, id: '1') do
          doc.text('content')
        end
      end
      expect(xml).to include('xmlns:ns="http://example.com/ns"')
      expect(xml).to include('id="1"')
      expect(xml).to include('content</ns:item>')
    end

    it 'creates namespace-prefixed tags via tag method with string names' do
      xml = described_class.build do |doc|
        doc.tag('soap:Envelope', 'xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/') do
          doc.tag('soap:Body')
        end
      end
      expect(xml).to include('<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">')
      expect(xml).to include('<soap:Body />')
    end

    it 'handles namespace_tag without a registered namespace' do
      xml = described_class.build do |doc|
        doc.namespace_tag(:custom, :element)
      end
      expect(xml).to include('<custom:element />')
      expect(xml).not_to include('xmlns:custom')
    end

    it 'supports symbol attribute keys with double underscores as namespace separator' do
      xml = described_class.build do |doc|
        doc.tag(:item, xmlns__custom: 'http://example.com')
      end
      expect(xml).to include('xmlns:custom="http://example.com"')
    end
  end

  describe 'SOAP envelope builder' do
    it 'builds a SOAP 1.1 envelope' do
      xml = described_class.build do |doc|
        doc.soap_envelope do |_header, body|
          body << ->(d) { d.tag('GetPrice') { d.text('Widget') } }
        end
      end
      expect(xml).to include('xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"')
      expect(xml).to include('<soap:Envelope')
      expect(xml).to include('<soap:Header')
      expect(xml).to include('<soap:Body')
      expect(xml).to include('<GetPrice>Widget</GetPrice>')
    end

    it 'builds a SOAP 1.2 envelope' do
      xml = described_class.build do |doc|
        doc.soap_envelope(version: '1.2') do |_header, body|
          body << ->(d) { d.tag('GetPrice') }
        end
      end
      expect(xml).to include('xmlns:soap="http://www.w3.org/2003/05/soap-envelope"')
      expect(xml).to include('<soap:Envelope')
    end

    it 'supports header and body content' do
      xml = described_class.build do |doc|
        doc.soap_envelope do |header, body|
          header << ->(d) { d.tag('auth') { d.text('token123') } }
          body << ->(d) { d.tag('request') { d.text('data') } }
        end
      end
      expect(xml).to include('<soap:Header><auth>token123</auth></soap:Header>')
      expect(xml).to include('<soap:Body><request>data</request></soap:Body>')
    end

    it 'raises an error for unsupported SOAP version' do
      expect do
        described_class.build do |doc|
          doc.soap_envelope(version: '2.0') { |_h, _b| }
        end
      end.to raise_error(Philiprehberger::XmlBuilder::Error, /Unsupported SOAP version/)
    end

    it 'builds an empty SOAP envelope without a block' do
      xml = described_class.build(&:soap_envelope)
      expect(xml).to include('<soap:Envelope')
      expect(xml).to include('<soap:Header')
      expect(xml).to include('<soap:Body')
    end

    it 'works via the build_soap convenience method' do
      xml = described_class.build_soap(soap_version: '1.1') do |_header, body|
        body << ->(d) { d.tag('Action') { d.text('test') } }
      end
      expect(xml).to start_with('<?xml version="1.0" encoding="UTF-8"?>')
      expect(xml).to include('<soap:Envelope')
      expect(xml).to include('<Action>test</Action>')
    end

    it 'build_soap supports SOAP 1.2' do
      xml = described_class.build_soap(soap_version: '1.2') do |_header, body|
        body << ->(d) { d.tag('Ping') }
      end
      expect(xml).to include('xmlns:soap="http://www.w3.org/2003/05/soap-envelope"')
    end
  end

  describe 'XML fragment composition' do
    it 'appends children from one document to another' do
      fragment = Philiprehberger::XmlBuilder::Document.new
      fragment.tag(:item, id: '1') { fragment.text('first') }
      fragment.tag(:item, id: '2') { fragment.text('second') }

      xml = described_class.build do |doc|
        doc.tag(:root) do
          doc.append(fragment)
        end
      end
      expect(xml).to include('<item id="1">first</item>')
      expect(xml).to include('<item id="2">second</item>')
      expect(xml).to include('<root><item id="1">first</item><item id="2">second</item></root>')
    end

    it 'appends at the document root level' do
      fragment = Philiprehberger::XmlBuilder::Document.new
      fragment.tag(:section) { fragment.text('content') }

      xml = described_class.build do |doc|
        doc.append(fragment)
      end
      expect(xml).to include('<section>content</section>')
    end

    it 'raises an error when appending a non-Document' do
      expect do
        described_class.build do |doc|
          doc.append('not a document')
        end
      end.to raise_error(Philiprehberger::XmlBuilder::Error, /append expects a Document/)
    end

    it 'inserts a raw XML fragment string' do
      xml = described_class.build do |doc|
        doc.tag(:root) do
          doc.insert_fragment('<existing>data</existing>')
        end
      end
      expect(xml).to include('<root><existing>data</existing></root>')
    end

    it 'composes multiple fragments into a single document' do
      header_fragment = Philiprehberger::XmlBuilder::Document.new
      header_fragment.tag(:title) { header_fragment.text('My Doc') }

      body_fragment = Philiprehberger::XmlBuilder::Document.new
      body_fragment.tag(:paragraph) { body_fragment.text('Hello world') }

      xml = described_class.build do |doc|
        doc.tag(:document) do
          doc.tag(:header) { doc.append(header_fragment) }
          doc.tag(:body) { doc.append(body_fragment) }
        end
      end
      expect(xml).to include('<header><title>My Doc</title></header>')
      expect(xml).to include('<body><paragraph>Hello world</paragraph></body>')
    end

    it 'combines fragment composition with namespaces' do
      fragment = Philiprehberger::XmlBuilder::Document.new
      fragment.tag('wsse:UsernameToken') do
        fragment.tag('wsse:Username') { fragment.text('admin') }
      end

      xml = described_class.build do |doc|
        doc.tag('soap:Envelope', 'xmlns:soap' => 'http://schemas.xmlsoap.org/soap/envelope/',
                                 'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd') do
          doc.tag('soap:Header') do
            doc.append(fragment)
          end
          doc.tag('soap:Body')
        end
      end
      expect(xml).to include('<wsse:UsernameToken>')
      expect(xml).to include('<wsse:Username>admin</wsse:Username>')
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
