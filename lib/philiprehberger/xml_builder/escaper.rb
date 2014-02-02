# frozen_string_literal: true

module Philiprehberger
  module XmlBuilder
    # XML entity escaping for text content and attribute values.
    module Escaper
      ENTITIES = {
        '&' => '&amp;',
        '<' => '&lt;',
        '>' => '&gt;',
        '"' => '&quot;',
        "'" => '&apos;'
      }.freeze

      ENTITY_PATTERN = Regexp.union(ENTITIES.keys).freeze

      # Escape special XML characters in a string.
      #
      # @param text [String] the text to escape
      # @return [String] the escaped text
      def self.escape(text)
        text.to_s.gsub(ENTITY_PATTERN, ENTITIES)
      end
    end
  end
end
