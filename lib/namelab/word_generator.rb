# frozen_string_literal: true

require "dry-initializer"
require "dry-types"
require "yieldable"

module Namelab
  # The word generator class.
  class WordGenerator
    include Dry::Initializer.define -> do
      param :target_length, type: Dry::Types['params.integer']
      option :normalize, type: Dry::Types['params.bool'], default: proc { true }
    end

    extend Yieldable[:new]

    attr_reader :word

    def word
      @word ||= String.new
    end

    # Generates word and cleanups instance variables.
    def generate
      while chars_left > 0
        word << sample_syllable
        normalize! if normalize
      end
      return @word.capitalize
    ensure
      cleanup!
    end

    alias_method :call, :generate

    # Calculates how many chars are left to generate.
    def chars_left
      @target_length - word.length
    end

    LengthFilter = -> (op, len, syl) { syl.length.send(op, len) }.freeze.curry(3).freeze

    # Fetches random syllable.
    def sample_syllable
      filter = LengthFilter[:<=, chars_left.next] if chars_left <= 3
      Registry['syls.sample'][filter].to_s
    end

    private

    def normalize!
      @word.sub!(/([^aeiouy]{2})[^aeiouy]/, '\1')
      @word = @word[0, @target_length]
    end

    def cleanup!
      remove_instance_variable(:@word)
    end
  end
end