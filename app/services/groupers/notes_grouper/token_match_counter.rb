# frozen_string_literal: true

module Groupers
  class NotesGrouper
    # Counts how many noteN tokens in a description match a given token, where N
    # is any positive integer. Used to determine whether a token is unique
    # enough to be used as a seed for grouping.
    class TokenMatchCounter
      def initialize(description:)
        @description = description
      end

      def count(token)
        description
          .slice(*description.keys.grep(/note.+(displayLabel|type)/))
          .group_by { |k, _v| k.match(/(.*note\d+)\./)[1] }
          .count { |_key, value| tuple_matches?(value, token) }
      end

      private

      attr_reader :description

      def tuple_matches?(value, token)
        hash = value.to_h
        num = hash.keys.first[/\d+/]

        Token.from_grouped_hash(hash, num) == token ||
          Token.from_ungrouped_hash(hash, num) == token
      end
    end
  end
end
