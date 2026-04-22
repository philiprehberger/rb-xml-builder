# frozen_string_literal: true

module Philiprehberger
  module XmlBuilder
    # Represents an XML processing instruction (PI).
    #
    # Renders as <?target key="value" key2="value2"?>, with attribute
    # values escaped via Escaper.
    class ProcessingInstruction
      attr_reader :target, :attributes

      # @param target [String] the PI target name
      # @param attributes [Hash] attribute key/value pairs
      def initialize(target, attributes = {})
        @target = target.to_s
        @attributes = attributes
      end

      # Render this processing instruction as an XML string.
      #
      # @param indent [Integer, nil] number of spaces per indentation level, or nil for compact output
      # @param level [Integer] current nesting depth (used internally)
      # @param pretty [Boolean] whether to apply pretty-print formatting
      # @return [String] the rendered processing instruction
      def to_xml(indent: nil, level: 0, pretty: false)
        prefix = indent && pretty ? ' ' * (indent * level) : ''
        newline = indent && pretty ? "\n" : ''
        "#{prefix}<?#{@target}#{render_attributes}?>#{newline}"
      end

      # Alias for to_xml to match Node#render semantics.
      def render(indent: nil, level: 0)
        to_xml(indent: indent, level: level, pretty: !indent.nil?)
      end

      private

      def render_attributes
        return '' if @attributes.empty?

        pairs = @attributes.map do |key, value|
          attr_name = key.to_s.gsub('__', ':')
          " #{attr_name}=\"#{Escaper.escape(value)}\""
        end
        pairs.join
      end
    end
  end
end
