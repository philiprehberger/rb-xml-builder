# frozen_string_literal: true

require_relative 'xml_builder/version'
require_relative 'xml_builder/escaper'
require_relative 'xml_builder/node'
require_relative 'xml_builder/document'

module Philiprehberger
  module XmlBuilder
    class Error < StandardError; end

    # Build an XML document using a block-based DSL.
    #
    # @param encoding [String] XML encoding declaration (default: "UTF-8")
    # @param version [String] XML version declaration (default: "1.0")
    # @yield [Document] the document builder
    # @return [String] the rendered XML string
    def self.build(encoding: 'UTF-8', version: '1.0', declaration: true, &block)
      doc = Document.new(version: version, encoding: encoding, declaration: declaration)
      block.call(doc)
      doc.to_s
    end

    # Build a SOAP envelope document.
    #
    # Convenience wrapper around Document#soap_envelope that creates
    # a full XML document with the proper SOAP structure.
    #
    # @param soap_version [String] SOAP version: "1.1" or "1.2"
    # @param encoding [String] XML encoding declaration (default: "UTF-8")
    # @param version [String] XML version declaration (default: "1.0")
    # @yield [header, body] yields two arrays; push lambdas that accept a doc
    # @return [String] the rendered SOAP XML string
    def self.build_soap(soap_version: '1.1', encoding: 'UTF-8', version: '1.0', declaration: true, &block)
      doc = Document.new(version: version, encoding: encoding, declaration: declaration)
      doc.soap_envelope(version: soap_version, &block)
      doc.to_s
    end
  end
end
