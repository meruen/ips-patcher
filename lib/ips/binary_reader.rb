module Ips
  class BinaryReader
    attr_reader :data

    def initialize(data)
      @data = StringIO.new(data)
    end

    def read_string(size)
      @data.read(size)
    end

    def read_int24
      bytes = @data.read(3).bytes
      (bytes[0] << 16) | (bytes[1] << 8) | bytes[2]
    end

    def read_int8
      bytes = @data.read(2).bytes
      (bytes[0] << 8) | bytes[1]
    end

    def read_bytes(n_bytes)
      @data.read(n_bytes)
    end

    def go_back(n_bytes)
      @data.seek(-n_bytes, IO::SEEK_CUR)
    end
  end
end