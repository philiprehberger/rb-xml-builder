# frozen_string_literal: true

module Philiprehberger
  module XmlBuilder
    # Accumulates XML nodes and renders the final document.
    #
    # Used as the context object inside XmlBuilder.build blocks.
    class Document
      attr_reader :version, :encoding, :children

      # @param version [String] XML version for the declaration
      # @param encoding [String] XML encoding for the declaration
      def initialize(version: '1.0', encoding: 'UTF-8', declaration: true)
        @version = version
        @encoding = encoding
        @declaration = declaration
        @children = []
        @node_stack = []
        @namespaces = {}
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
        raise Error, 'CDATA content must not contain "]]>"' if content.to_s.include?(']]>')

        current_parent.push("<![CDATA[#{content}]]>")
      end

      # Add an XML comment.
      #
      # @param text [String] the comment text
      # @return [void]
      def comment(text)
        raise Error, 'Comment text must not contain "--"' if text.to_s.include?('--')

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
        parts = []

        if @declaration
          parts << "<?xml version=\"#{@version}\" encoding=\"#{@encoding}\"?>"
          parts << (indent ? "\n" : '')
        end

        @children.each do |child|
          parts << render_child(child, indent: indent, level: 0)
        end

        parts.join
      end

      # Register an XML namespace prefix and URI.
      #
      # Registered namespaces are automatically added as xmlns attributes
      # when using namespace_tag.
      #
      # @param prefix [String, Symbol] the namespace prefix
      # @param uri [String] the namespace URI
      # @return [void]
      def namespace(prefix, uri)
        @namespaces[prefix.to_s] = uri
      end

      # Add a namespace-prefixed element.
      #
      # Automatically includes the xmlns declaration for the prefix if it was
      # registered via #namespace and this is the first use in the current scope.
      #
      # @param prefix [String, Symbol] the namespace prefix
      # @param name [String, Symbol] the local element name
      # @param attributes [Hash] additional element attributes
      # @yield optional block for adding child elements
      # @return [Node] the created node
      def namespace_tag(prefix, name, attributes = {}, &)
        prefixed_name = "#{prefix}:#{name}"
        uri = @namespaces[prefix.to_s]
        attrs = if uri
                  { "xmlns:#{prefix}" => uri }.merge(attributes)
                else
                  attributes
                end
        tag(prefixed_name, attrs, &)
      end

      # Build a SOAP envelope using a block-based DSL.
      #
      # Supports SOAP 1.1 (default) and 1.2. Automatically sets the correct
      # namespace URI and creates the Envelope, Header, and Body elements.
      #
      # @param version [String] SOAP version: "1.1" or "1.2"
      # @yield [header, body] yields two procs for adding header and body content
      # @return [void]
      def soap_envelope(version: '1.1')
        uri = case version
              when '1.1' then 'http://schemas.xmlsoap.org/soap/envelope/'
              when '1.2' then 'http://www.w3.org/2003/05/soap-envelope'
              else
                raise Error, "Unsupported SOAP version: #{version}. Use '1.1' or '1.2'."
              end

        header_children = []
        body_children = []

        yield(header_children, body_children) if block_given?

        tag('soap:Envelope', 'xmlns:soap' => uri) do
          tag('soap:Header') do
            header_children.each { |child_block| child_block.call(self) }
          end
          tag('soap:Body') do
            body_children.each { |child_block| child_block.call(self) }
          end
        end
      end

      # Append children from another Document into this document.
      #
      # Copies all top-level children from the source document into the current
      # insertion point (either the document root or the current parent element).
      #
      # @param other [Document] the source document whose children to import
      # @return [void]
      def append(other)
        raise Error, 'append expects a Document' unless other.is_a?(Document)

        other.children.each do |child|
          current_parent.push(child)
        end
      end

      # Insert a raw XML fragment string into the current position.
      #
      # This is an alias for #raw, provided for semantic clarity when composing
      # fragments.
      #
      # @param xml_string [String] the XML fragment to insert
      # @return [void]
      def insert_fragment(xml_string)
        raw(xml_string)
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
