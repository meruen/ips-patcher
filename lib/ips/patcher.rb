# frozen_string_literal: true

require_relative "patcher/version"
require_relative "binary_reader"
require_relative "binary_writer"

module Ips
  # IPS (International Patching System) patcher for applying binary patches to ROM files.
  #
  # The IPS format is a binary patch format commonly used to distribute patches
  # for ROM images of video games. This module provides functionality to read
  # IPS patch files and apply them to ROM files.
  #
  # @example Basic usage
  #   Ips::Patcher.apply("game.rom", "patch.ips")
  #   # Creates: game.patched.rom
  #
  # @see https://zerosoft.zophar.net/ips.php IPS File Format Specification
  module Patcher
    # Error class for Patcher-specific errors
    class Error < StandardError; end
    
    # Applies an IPS patch file to a ROM file.
    #
    # This method reads both the ROM and patch files, validates the patch format,
    # and applies all patch records to create a new patched ROM file. The output
    # file is named with ".patched" inserted before the file extension.
    #
    # The IPS format supports two types of records:
    # - Standard records: Replace bytes at a specific offset
    # - RLE records: Fill bytes with a repeated value (when size is 0)
    #
    # @param rom_path [String] path to the ROM file to be patched
    # @param patch_path [String] path to the IPS patch file
    # @raise [Error] if the patch file does not have a valid "PATCH" header
    # @return [void]
    #
    # @example Apply a patch
    #   Ips::Patcher.apply("game.nes", "translation.ips")
    #   # Output: game.patched.nes
    #
    # @note The original ROM file is not modified; a new patched file is created
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
        size   = reader.read_int16

        if size == 0
          rle_size  = reader.read_int16
          rle_value = reader.read_bytes(1)
          writer.set_bytes(offset, rle_value * rle_size)
          next
        end

        bytes = reader.read_bytes(size)
        writer.set_bytes(offset, bytes)        
      end

      rom_dir     = File.dirname(rom_path)
      filename    = File.basename(rom_path, File.extname(rom_path))
      extension   = File.extname(rom_path)
      output_path = File.join(rom_dir, "#{filename}.patched#{extension}")

      writer.save_to_file(output_path)
    end
  end
end
