module Ips
  class BinaryWriter
    class Error < StandardError; end

    attr_reader :data

    def initialize(data)
      raise Error, "Data cannot be nil" if data.nil?
      raise Error, "Data must be a String" unless data.is_a?(String)
      
      @data = StringIO.new(data.b)
    rescue => e
      raise Error, "Failed to initialize BinaryWriter: #{e.message}"
    end

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