# frozen_string_literal: true

module Groupers
  class NotesGrouper
    # Counts occurrences of a note token within note tuple-bearing keys
    # of a single flattened description.
    class TokenMatchCounter
      # @param description [Hash{String => String}]
      # @return [void]
      def initialize(description:)
        @description = description
      end

      # Counts logical note entries that match the provided token.
      #
      # @param token [Token]
      # @return [Integer]
      def count(token)
        description
          .slice(*description.keys.grep(/#{PREFIX}.+(displayLabel|type)/o))
          .group_by { |key, _value| key.match(/(.*#{PREFIX}\d+)\./o)[1] }
          .count { |_key, value| tuple_matches?(value, token) }
      end

      private

      # @return [Hash{String => String}]
      attr_reader :description

      # @param value [Array<Array(String, Object)>]
      #   Grouped key pairs for one logical note prefix.
      # @param token [Token]
      # @return [Boolean]
      def tuple_matches?(value, token)
        hash = value.to_h
        num = hash.keys.first[/\d+/]

        Token.from_grouped_hash(hash, num) == token || Token.from_ungrouped_hash(hash, num) == token
      end
    end
  end
end
