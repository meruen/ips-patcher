module Ips
  # Binary data writer for modifying ROM files with patch data.
  # 
  # This class provides methods to write bytes at specific offsets
  # and save the modified data to a file. It includes comprehensive
  # error handling and validation.
  #
  # @example Writing bytes and saving
  #   rom_data = File.binread("game.rom")
  #   writer = Ips::BinaryWriter.new(rom_data)
  #   writer.set_bytes(0x1000, "\x42\x43\x44")
  #   writer.save_to_file("game_patched.rom")
  class BinaryWriter
    # Error class for BinaryWriter-specific errors
    class Error < StandardError; end

    # @return [StringIO] the internal StringIO object containing the binary data
    attr_reader :data

    # Creates a new BinaryWriter instance.
    #
    # @param data [String] the binary data to write to
    # @raise [Error] if data is nil or not a String
    # @return [BinaryWriter] a new instance of BinaryWriter
    def initialize(data)
      raise Error, "Data cannot be nil" if data.nil?
      raise Error, "Data must be a String" unless data.is_a?(String)
      
      @data = StringIO.new(data.b)
    rescue => e
      raise Error, "Failed to initialize BinaryWriter: #{e.message}"
    end

    # Writes bytes at a specific offset in the data.
    #
    # @param offset [Integer] the position to write the bytes at
    # @param bytes [String] the bytes to write
    # @raise [Error] if offset is nil, not numeric, or negative
    # @raise [Error] if bytes is nil or not a String
    # @raise [Error] if an IO or system error occurs during writing
    # @return [void]
    def set_bytes(offset, bytes)
      raise Error, "Offset cannot be nil" if offset.nil?
      raise Error, "Offset must be a numeric value" unless offset.is_a?(Numeric)
      raise Error, "Offset cannot be negative" if offset < 0
      raise Error, "Bytes cannot be nil" if bytes.nil?
      raise Error, "Bytes must be a String" unless bytes.is_a?(String)

      @data.seek(offset)
      @data.write(bytes)
    rescue IOError, SystemCallError => e
      raise Error, "Failed to write bytes at offset #{offset}: #{e.message}"
    end

    # Saves the current data to a file.
    #
    # @param path [String] the file path to save to
    # @raise [Error] if path is nil or empty
    # @raise [Error] if the directory does not exist
    # @raise [Error] if permission is denied
    # @raise [Error] if no space is left on the device
    # @raise [Error] if an IO or system error occurs during saving
    # @return [void]
    def save_to_file(path)
      raise Error, "Path cannot be nil or empty" if path.nil? || path.to_s.empty?

      File.binwrite(path, @data.string)
    rescue Errno::ENOENT => e
      raise Error, "Directory does not exist: #{e.message}"
    rescue Errno::EACCES => e
      raise Error, "Permission denied: #{e.message}"
    rescue Errno::ENOSPC => e
      raise Error, "No space left on device: #{e.message}"
    rescue IOError, SystemCallError => e
      raise Error, "Failed to save file to #{path}: #{e.message}"
    end
  end
end