# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::XmlBuilder::ProcessingInstruction do
  describe '#to_xml' do
    it 'emits a basic PI with no attributes' do
      pi = described_class.new('xml-stylesheet')
      expect(pi.to_xml).to eq('<?xml-stylesheet?>')
    end

    it 'emits a PI with multiple attributes in declaration order' do
      pi = described_class.new('xml-stylesheet', href: 'style.xsl', type: 'text/xsl')
      expect(pi.to_xml).to eq('<?xml-stylesheet href="style.xsl" type="text/xsl"?>')
    end

    it 'escapes " and & in attribute values' do
      pi = described_class.new('xml-stylesheet', title: 'Tom & "Jerry"')
      expect(pi.to_xml).to eq('<?xml-stylesheet title="Tom &amp; &quot;Jerry&quot;"?>')
    end
  end

  describe 'Document#processing_instruction' do
    it 'renders a PI inside a document with keyword attrs' do
      xml = Philiprehberger::XmlBuilder.build do |doc|
        doc.processing_instruction('xml-stylesheet', href: 'style.xsl', type: 'text/xsl')
        doc.tag(:root)
      end
      expect(xml).to include('<?xml-stylesheet href="style.xsl" type="text/xsl"?>')
    end

    it 'raises ArgumentError on empty target' do
      expect do
        Philiprehberger::XmlBuilder.build do |doc|
          doc.processing_instruction('')
        end
      end.to raise_error(ArgumentError, /non-empty String/)
    end

    it 'raises ArgumentError on target "xml" (lowercase)' do
      expect do
        Philiprehberger::XmlBuilder.build do |doc|
          doc.processing_instruction('xml', href: 'style.xsl')
        end
      end.to raise_error(ArgumentError, /reserved/)
    end

    it 'raises ArgumentError on target "XML" (uppercase)' do
      expect do
        Philiprehberger::XmlBuilder.build do |doc|
          doc.processing_instruction('XML', href: 'style.xsl')
        end
      end.to raise_error(ArgumentError, /reserved/)
    end

    it 'raises ArgumentError on target "Xml" (mixed case)' do
      expect do
        Philiprehberger::XmlBuilder.build do |doc|
          doc.processing_instruction('Xml', href: 'style.xsl')
        end
      end.to raise_error(ArgumentError, /reserved/)
    end
  end

  describe 'Document#pi alias' do
    it 'is an alias for #processing_instruction' do
      doc = Philiprehberger::XmlBuilder::Document.new
      expect(doc.method(:pi)).to eq(doc.method(:processing_instruction))
    end

    it 'emits the same output as #processing_instruction' do
      via_pi = Philiprehberger::XmlBuilder.build do |doc|
        doc.pi('xml-stylesheet', href: 'style.xsl', type: 'text/xsl')
        doc.tag(:root)
      end
      via_full = Philiprehberger::XmlBuilder.build do |doc|
        doc.processing_instruction('xml-stylesheet', href: 'style.xsl', type: 'text/xsl')
        doc.tag(:root)
      end
      expect(via_pi).to eq(via_full)
    end
  end
end
