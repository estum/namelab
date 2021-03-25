# frozen_string_literal: true

require "tempfile"

module Namelab
  class ListRef
    attr_reader :proc, :lines_count

    def initialize(io_proc)
      @proc = io_proc
      sync!
    end

    def lines(enum: true, &block)
      enum ? each_line(&block) : block.(each_line)
    ensure
      rewind
    end

    def each_line(&block)
      return to_enum(:each_line) unless block_given?
      io.each_line(chomp: true, &block)
    end

    def io
      @io ||= @proc[]
    end

    def with_io
      io
      yield(self)
    ensure
      close
    end

    def close
      @io&.close
      if defined?(@_tmp)
        File.unlink(@_tmp)
        remove_instance_variable(:@_tmp)
      end
      remove_instance_variable(:@io)
    end

    def rewind
      @io&.rewind
    end

    def sample_lineno
      rand(lines_count)
    end

    def filter(&block) # :yields:
      @filter = block.to_proc
      self
    end

    def sample(filter = true)
      if filter && defined?(@filter)
        proc = @filter
        remove_instance_variable(:@filter)
        filtered_sample(&proc)
      else
        get(sample_lineno).strip
      end
    end

    def filtered_sample # :yields:
      result = nil
      while result.nil?
        value = sample(false)
        redo unless yield(value)
        result = value
      end
      result
    end

    def get(lineno)
      offset = lineno * @sample_size
      begin
        @io.pread(@sample_size, offset)
      rescue EOFError
        offset -= @sample_size
        retry
      end
    end

    NORMALIZED_FMT = "%1$*2$s"

    def sync!
      remove_instance_variable(:@_tmp) if defined?(@_tmp)
      tempfile = Tempfile.new(File.basename(io.path))
      lines enum: false do |enum|
        @sample_size = enum.max_by(&:length).length
        rewind
        lines_count = 0
        enum.each do |v|
          tempfile.printf(NORMALIZED_FMT, v, -@sample_size)
          lines_count += 1
        end
        @lines_count = lines_count
      end
      tempfile.rewind
      close
      @_tmp = tempfile.path
      @io = tempfile.to_io
      at_exit { close }
    end
  end
end
