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
    def self.build(encoding: 'UTF-8', version: '1.0', &block)
      doc = Document.new(version: version, encoding: encoding)
      block.call(doc)
      doc.to_s
    end
  end
end
