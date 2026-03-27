# frozen_string_literal: true

module Philiprehberger
  module XmlBuilder
    # Accumulates XML nodes and renders the final document.
    #
    # Used as the context object inside XmlBuilder.build blocks.
    class Document
      attr_reader :version, :encoding

      # @param version [String] XML version for the declaration
      # @param encoding [String] XML encoding for the declaration
      def initialize(version: '1.0', encoding: 'UTF-8')
        @version = version
        @encoding = encoding
        @children = []
        @node_stack = []
      end

      # Add an XML element with optional attributes and nested children.
      #
      # @param name [String, Symbol] the element tag name
      # @param attributes [Hash] element attributes
      # @yield optional block for adding child elements
      # @return [Node] the created node
      def tag(name, attributes = {}, &block)
        node = Node.new(name, attributes)

        if block
          @node_stack.push(node)
          block.call
          @node_stack.pop
        end

        current_parent.push(node)
        node
      end

      # Add escaped text content to the current element.
      #
      # @param content [String] the text content to escape and add
      # @return [void]
      def text(content)
        current_parent.push(Escaper.escape(content.to_s))
      end

      # Add a CDATA section.
      #
      # @param content [String] the CDATA content (must not contain "]]>")
      # @return [void]
      def cdata(content)
        current_parent.push("<![CDATA[#{content}]]>")
      end

      # Add an XML comment.
      #
      # @param text [String] the comment text
      # @return [void]
      def comment(text)
        current_parent.push("<!-- #{text} -->")
      end

      # Add a processing instruction.
      #
      # @param target [String] the PI target
      # @param content [String] the PI content
      # @return [void]
      def processing_instruction(target, content)
        current_parent.push("<?#{target} #{content}?>")
      end

      # Add raw XML content without escaping.
      #
      # @param string [String] raw XML string
      # @return [void]
      def raw(string)
        current_parent.push(string.to_s)
      end

      # Render the document as a compact XML string (no indentation).
      #
      # @return [String] the rendered XML document
      def to_s
        to_xml
      end

      # Render the document as an XML string with optional indentation.
      #
      # @param indent [Integer, nil] number of spaces per indentation level, or nil for compact output
      # @return [String] the rendered XML document
      def to_xml(indent: nil)
        parts = ["<?xml version=\"#{@version}\" encoding=\"#{@encoding}\"?>"]
        parts << (indent ? "\n" : '')

        @children.each do |child|
          parts << render_child(child, indent: indent, level: 0)
        end

        parts.join
      end

      # Support method_missing for DSL-style tag creation.
      #
      # @example
      #   xml.person(name: "John") { xml.age("30") }
      #   # => <person name="John"><age>30</age></person>
      def method_missing(method_name, *args, &block)
        first_arg = args.first
        attributes = {}
        text_content = nil

        if first_arg.is_a?(Hash)
          attributes = first_arg
        elsif first_arg
          text_content = first_arg.to_s
          attributes = args[1] if args[1].is_a?(Hash)
        end

        if text_content
          tag(method_name, attributes) { text(text_content) }
        elsif block
          tag(method_name, attributes, &block)
        else
          tag(method_name, attributes)
        end
      end

      # @return [Boolean]
      def respond_to_missing?(_method_name, _include_private = false)
        true
      end

      private

      def current_parent
        @node_stack.last&.children || @children
      end

      def render_child(child, indent:, level:)
        case child
        when Node
          child.render(indent: indent, level: level)
        when String
          if indent
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
