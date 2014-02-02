# frozen_string_literal: true

module Philiprehberger
  module XmlBuilder
    # Represents a single XML element with optional attributes and children.
    class Node
      attr_reader :name, :attributes, :children

      # @param name [String, Symbol] the element tag name
      # @param attributes [Hash] element attributes
      def initialize(name, attributes = {})
        @name = name.to_s
        @attributes = attributes
        @children = []
      end

      # Render this node and its children as an XML string.
      #
      # @param indent [Integer, nil] number of spaces per indentation level, or nil for compact output
      # @param level [Integer] current nesting depth (used internally)
      # @return [String] the rendered XML
      def render(indent: nil, level: 0)
        prefix = indent ? ' ' * (indent * level) : ''
        newline = indent ? "\n" : ''

        attrs = render_attributes
        tag_open = "#{prefix}<#{@name}#{attrs}"

        if @children.empty?
          "#{tag_open} />#{newline}"
        else
          parts = ["#{tag_open}>"]
          inline = !indent || @children.all?(String)

          if inline
            @children.each { |child| parts << render_child(child, indent: nil, level: 0) }
            parts << "</#{@name}>#{newline}"
          else
            parts[0] << newline
            @children.each { |child| parts << render_child(child, indent: indent, level: level + 1) }
            parts << "#{prefix}</#{@name}>#{newline}"
          end
          parts.join
        end
      end

      private

      def render_attributes
        return '' if @attributes.empty?

        pairs = @attributes.map do |key, value|
          " #{key}=\"#{Escaper.escape(value)}\""
        end
        pairs.join
      end

      def render_child(child, indent:, level:)
        case child
        when Node
          child.render(indent: indent, level: level)
        when String
          if indent && level.positive?
            "#{' ' * (indent * level)}#{child}\n"
          else
            child
          end
        else
          child.to_s
        end
      end
    end
  end
end
