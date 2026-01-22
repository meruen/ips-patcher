# Namespace for IPS (International Patching System) patcher functionality.
#
# This module provides classes and methods for reading, parsing, and applying
# IPS patch files to binary ROM images. The IPS format is commonly used to
# distribute patches for video game ROM files.
#
# @see Ips::Patcher The main module for applying patches
# @see Ips::BinaryReader Reader for parsing binary data
# @see Ips::BinaryWriter Writer for modifying binary data
module Ips
  # Binary data reader for parsing IPS patch files.
  # 
  # This class provides methods to read various data types from binary data,
  # including strings, integers of different sizes, and raw bytes.
  #
  # @example Reading from binary data
  #   data = File.binread("patch.ips")
  #   reader = Ips::BinaryReader.new(data)
  #   header = reader.read_string(5) # => "PATCH"
  class BinaryReader
    # @return [StringIO] the internal StringIO object containing the binary data
    attr_reader :data

    # Creates a new BinaryReader instance.
    #
    # @param data [String] the binary data to read from
    # @return [BinaryReader] a new instance of BinaryReader
    def initialize(data)
      @data = StringIO.new(data)
    end

    # Reads a string of specified size from the current position.
    #
    # @param size [Integer] the number of bytes to read
    # @return [String] the string read from the data
    def read_string(size)
      @data.read(size)
    end

    # Reads a 24-bit big-endian integer (3 bytes) from the current position.
    #
    # @return [Integer] the 24-bit integer value
    def read_int24
      bytes = @data.read(3).bytes
      (bytes[0] << 16) | (bytes[1] << 8) | bytes[2]
    end

    # Reads a 16-bit big-endian integer (2 bytes) from the current position.
    #
    # @return [Integer] the 16-bit integer value
    def read_int16
      bytes = @data.read(2).bytes
      (bytes[0] << 8) | bytes[1]
    end

    # Reads a specified number of raw bytes from the current position.
    #
    # @param n_bytes [Integer] the number of bytes to read
    # @return [String] the raw bytes as a binary string
    def read_bytes(n_bytes)
      @data.read(n_bytes)
    end

    # Moves the read position backwards by a specified number of bytes.
    #
    # @param n_bytes [Integer] the number of bytes to move back
    # @return [Integer] the new position in the stream
    def go_back(n_bytes)
      @data.seek(-n_bytes, IO::SEEK_CUR)
    end
  end
end