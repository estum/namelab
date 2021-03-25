# frozen_string_literal: true

require "dry/container"
require "namelab/list_ref"

module Namelab
  module Registry
    extend Dry::Container::Mixin

    namespace :syls do
      register :sample, call: false do |proc = nil|
        ref = proc.is_a?(Proc) ? resolve(:ref).filter(&proc) : resolve(:ref)
        ref.sample
      end

      register :ref, memoize: true do
        ListRef.new(resolve(:io_proc))
      end

      register :io_proc, call: false do
        File.new(resolve(:path), textmode: true)
      end

      register :path, File.expand_path("../syls.data", __dir__)
    end
  end
end
