# frozen_string_literal: true

require "ips/binary_writer"
require "tempfile"

RSpec.describe Ips::BinaryWriter do
  describe "#initialize" do
    it "creates a new BinaryWriter with binary data" do
      data = "PATCH\x00\x01\x02"
      writer = described_class.new(data)
      
      expect(writer.data).to be_a(StringIO)
      expect(writer.data.string).to eq(data)
    end

    it "handles empty string data" do
      writer = described_class.new("")
      expect(writer.data.string).to eq("")
    end

    it "handles binary data correctly" do
      data = "\x00\x01\x02\xFF\xFE".b
      writer = described_class.new(data)
      expect(writer.data.string).to eq(data.b)
    end

    context "error handling" do
      it "raises Error when data is nil" do
        expect {
          described_class.new(nil)
        }.to raise_error(Ips::BinaryWriter::Error, /Data cannot be nil/)
      end

      it "raises Error when data is not a String" do
        expect {
          described_class.new(123)
        }.to raise_error(Ips::BinaryWriter::Error, /Data must be a String/)
      end

      it "raises Error when data is an array" do
        expect {
          described_class.new([1, 2, 3])
        }.to raise_error(Ips::BinaryWriter::Error, /Data must be a String/)
      end
    end
  end

  describe "#set_bytes" do
    let(:initial_data) { "PATCH\x00\x01\x02\x03" }
    let(:writer) { described_class.new(initial_data) }

    it "writes bytes at the specified offset" do
      writer.set_bytes(0, "TEST")
      result = writer.data.string
      expect(result).to eq("TESTH\x00\x01\x02\x03".b)
    end

    it "overwrites existing bytes at offset" do
      writer.set_bytes(5, "\xFF\xFE")
      result = writer.data.string
      expect(result).to eq("PATCH\xFF\xFE\x02\x03".b)
    end

    it "writes bytes in the middle of the data" do
      writer.set_bytes(2, "XX")
      result = writer.data.string
      expect(result).to eq("PAXXH\x00\x01\x02\x03")
    end

    it "extends data when writing beyond current size" do
      writer.set_bytes(10, "EXTEND")
      result = writer.data.string
      expect(result[0..8]).to eq(initial_data)
      expect(result[10..15]).to eq("EXTEND")
    end

    it "handles single byte writes" do
      writer.set_bytes(0, "X")
      result = writer.data.string
      expect(result).to eq("XATCH\x00\x01\x02\x03")
    end

    it "handles binary bytes correctly" do
      writer.set_bytes(5, "\xFF\x00\xAA")
      result = writer.data.string
      expect(result[5..7]).to eq("\xFF\x00\xAA".b)
    end

    it "can write at offset 0" do
      writer.set_bytes(0, "START")
      result = writer.data.string
      expect(result).to start_with("START")
    end

    context "error handling" do
      let(:writer) { described_class.new("test data") }

      it "raises Error when offset is nil" do
        expect {
          writer.set_bytes(nil, "test")
        }.to raise_error(Ips::BinaryWriter::Error, "Offset cannot be nil")
      end

      it "raises Error when offset is not numeric" do
        expect {
          writer.set_bytes("invalid", "test")
        }.to raise_error(Ips::BinaryWriter::Error, "Offset must be a numeric value")
      end

      it "raises Error when offset is negative" do
        expect {
          writer.set_bytes(-1, "test")
        }.to raise_error(Ips::BinaryWriter::Error, "Offset cannot be negative")
      end

      it "raises Error when bytes is nil" do
        expect {
          writer.set_bytes(0, nil)
        }.to raise_error(Ips::BinaryWriter::Error, "Bytes cannot be nil")
      end

      it "raises Error when bytes is not a String" do
        expect {
          writer.set_bytes(0, 123)
        }.to raise_error(Ips::BinaryWriter::Error, "Bytes must be a String")
      end

      it "raises Error when bytes is an array" do
        expect {
          writer.set_bytes(0, [1, 2, 3])
        }.to raise_error(Ips::BinaryWriter::Error, "Bytes must be a String")
      end
    end
  end

  describe "#save_to_file" do
    let(:test_data) { "PATCH\x00\x01\x02\x03\xFF\xFE".b }
    let(:writer) { described_class.new(test_data) }

    it "saves data to a file correctly" do
      temp_file = Tempfile.new("test_output")
      temp_path = temp_file.path
      temp_file.close
      temp_file.unlink

      writer.save_to_file(temp_path)

      expect(File.exist?(temp_path)).to be true
      saved_data = File.binread(temp_path)
      expect(saved_data).to eq(test_data)

      File.delete(temp_path) if File.exist?(temp_path)
    end

    it "saves modified data correctly" do
      writer.set_bytes(0, "MODIFIED")
      
      temp_file = Tempfile.new("test_output")
      temp_path = temp_file.path
      temp_file.close
      temp_file.unlink

      writer.save_to_file(temp_path)

      saved_data = File.binread(temp_path)
      expect(saved_data).to start_with("MODIFIED")

      File.delete(temp_path) if File.exist?(temp_path)
    end

    it "overwrites existing files" do
      temp_file = Tempfile.new("test_output")
      temp_path = temp_file.path
      temp_file.write("old content")
      temp_file.close

      writer.save_to_file(temp_path)

      saved_data = File.binread(temp_path)
      expect(saved_data).to eq(test_data)
      expect(saved_data).not_to eq("old content".b)

      File.delete(temp_path) if File.exist?(temp_path)
    end

    it "saves binary data correctly" do
      binary_data = "\x00\x01\x02\xFF\xFE\xFD".b
      writer = described_class.new(binary_data)

      temp_file = Tempfile.new("test_output")
      temp_path = temp_file.path
      temp_file.close
      temp_file.unlink

      writer.save_to_file(temp_path)

      saved_data = File.binread(temp_path)
      expect(saved_data).to eq(binary_data)
      expect(saved_data.bytes).to eq([0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD])

      File.delete(temp_path) if File.exist?(temp_path)
    end

    context "error handling" do
      let(:writer) { described_class.new("test data") }

      it "raises Error when path is nil" do
        expect {
          writer.save_to_file(nil)
        }.to raise_error(Ips::BinaryWriter::Error, "Path cannot be nil or empty")
      end

      it "raises Error when path is empty string" do
        expect {
          writer.save_to_file("")
        }.to raise_error(Ips::BinaryWriter::Error, "Path cannot be nil or empty")
      end

      it "raises Error when directory does not exist" do
        expect {
          writer.save_to_file("/nonexistent/directory/file.bin")
        }.to raise_error(Ips::BinaryWriter::Error, /Directory does not exist/)
      end

      it "handles permission errors gracefully" do
        # On Unix systems, try to write to a read-only location
        if File.exist?("/etc") && !File.writable?("/etc")
          expect {
            writer.save_to_file("/etc/test_write.bin")
          }.to raise_error(Ips::BinaryWriter::Error, /Permission denied|Operation not permitted|Failed to save file/)
        end
      end
    end
  end

  describe "integration scenarios" do
    it "can write multiple patches and save" do
      rom_data = "\x00" * 100 # 100 bytes of zeros
      writer = described_class.new(rom_data)

      # Write multiple patches
      writer.set_bytes(10, "PATCH1")
      writer.set_bytes(30, "PATCH2")
      writer.set_bytes(50, "\xFF\xFE\xFD")

      temp_file = Tempfile.new("test_output")
      temp_path = temp_file.path
      temp_file.close
      temp_file.unlink

      writer.save_to_file(temp_path)

      saved_data = File.binread(temp_path)
      expect(saved_data[10..15]).to eq("PATCH1")
      expect(saved_data[30..35]).to eq("PATCH2")
      expect(saved_data[50..52]).to eq("\xFF\xFE\xFD".b)

      File.delete(temp_path) if File.exist?(temp_path)
    end

    it "can simulate IPS patching workflow" do
      # Simulate a ROM file
      rom_data = "ORIGINAL ROM DATA" + ("\x00" * 100)
      writer = described_class.new(rom_data)

      # Apply patches at different offsets
      writer.set_bytes(0, "PATCHED")
      writer.set_bytes(20, "\x42\x43\x44")

      temp_file = Tempfile.new("test_output")
      temp_path = temp_file.path
      temp_file.close
      temp_file.unlink

      writer.save_to_file(temp_path)

      saved_data = File.binread(temp_path)
      expect(saved_data).to start_with("PATCHED")
      expect(saved_data[20..22]).to eq("\x42\x43\x44")

      File.delete(temp_path) if File.exist?(temp_path)
    end
  end
end
