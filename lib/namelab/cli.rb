# frozen_string_literal: true

require "dry/cli"
require "shellwords"

module Namelab
  module CLI
    module InheritanceHook
      def inherited(base)
        super

        base.class_eval do
          %i(examples arguments options).each do |var|
            instance_variable_get("@#{var}").unshift(*superclass.public_send(var).dup)
          end
        end
      end
    end

    module Commands
      extend Dry::CLI::Registry

      class Generate < Dry::CLI::Command
        extend InheritanceHook

        argument :lengths, :type    => :array,
                           :default => [6],
                           :desc    => "Sequence of lengths for each target word separated by space"

        option :samples, :type    => :integer,
                         :default => 1,
                         :desc    => "Amount of generated samples",
                         :aliases => %w(-s)

        option :normalize, :type    => :boolean,
                           :default => true,
                           :desc    => "Normalize generated words, i.e. truncate to target length",
                           :aliases => %w(-N)

        def call(samples:, lengths: [], **opts)
          generators = lengths.each_with_object(opts).map(&WordGenerator)

          samples.to_i.times do
            outputing { generators.map(&:call).join(" ") }
          end
        end

        # Yields the block and outputs result.
        def outputing # :yields:
          result = yield
          fail "Empty result" unless result && result.size > 0
          output(result)
        end

        def output(result)
          puts result
        end
      end

      class Say < Generate
        DEFAULT_ARGS = %w(-i -v Victoria).freeze
        option :sayopt, :type => :string,
                        :default => DEFAULT_ARGS.shelljoin,
                        :desc    => "Arguments for say command"

        def call(sayopt:, **opts)
          @say_args = sayopt.shellsplit
          @say_args.unshift(*DEFAULT_ARGS) if @say_args != DEFAULT_ARGS
          super
        end

        def output(result)
          system("/usr/bin/say", *@say_args, result)
        end
      end

      register "gen", Generate, aliases: %w(generate g -g)
      register "say", Say,      aliases: %w(speak s -s)
    end
  end
end
