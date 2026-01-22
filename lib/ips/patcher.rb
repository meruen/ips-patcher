# frozen_string_literal: true

require_relative "patcher/version"
require_relative "binary_reader"
require_relative "binary_writer"

module Ips
  module Patcher
    class Error < StandardError; end
    
    def self.apply(rom_path, patch_path)
      rom = File.binread(rom_path)
      patch = File.binread(patch_path)

      reader = Ips::BinaryReader.new(patch)
      writer = Ips::BinaryWriter.new(rom)

      header = reader.read_string(5)
      if header != 'PATCH'
        raise Error, "Invalid patch file"
      end

      loop do
        eof = reader.read_string(3)
        break if eof == 'EOF'

        reader.go_back(3)

        offset = reader.read_int24
        size = reader.read_int8

        if size == 0
          rle_size = reader.read_int8
          rle_value = reader.read_bytes(1)
          writer.set_bytes(offset, rle_value * rle_size)
          next
        end

        bytes = reader.read_bytes(size)
        writer.set_bytes(offset, bytes)        
      end

      writer.save_to_file(File.basename(rom_path) + ".patched.#{File.extname(rom_path)}")
    end
  end
end
