# frozen_string_literal: true

require "ips/binary_reader"

RSpec.describe Ips::BinaryReader do
  describe "#initialize" do
    it "creates a new BinaryReader with binary data" do
      data = "PATCH\x00\x01\x02"
      reader = described_class.new(data)
      
      expect(reader.data).to be_a(StringIO)
      expect(reader.data.string).to eq(data)
    end
  end

  describe "#read_string" do
    let(:data) { "PATCH\x00\x01\x02\x03" }
    let(:reader) { described_class.new(data) }

    it "reads a string of specified size" do
      result = reader.read_string(5)
      expect(result).to eq("PATCH")
    end

    it "reads the correct number of bytes" do
      result = reader.read_string(3)
      expect(result).to eq("PAT")
      expect(result.bytesize).to eq(3)
    end

    it "advances the position after reading" do
      reader.read_string(3)
      expect(reader.data.pos).to eq(3)
    end

    it "reads binary data correctly" do
      result = reader.read_string(4)
      expect(result).to eq("PATC")
    end
  end

  describe "#read_int24" do
    it "reads a 24-bit big-endian integer correctly" do
      # 0x010203 = 66051 in decimal
      data = [0x01, 0x02, 0x03].pack("C*")
      reader = described_class.new(data)
      
      result = reader.read_int24
      expect(result).to eq(0x010203)
      expect(result).to eq(66051)
    end

    it "reads maximum 24-bit value correctly" do
      # 0xFFFFFF = 16777215
      data = [0xFF, 0xFF, 0xFF].pack("C*")
      reader = described_class.new(data)
      
      result = reader.read_int24
      expect(result).to eq(0xFFFFFF)
      expect(result).to eq(16777215)
    end

    it "reads minimum 24-bit value correctly" do
      # 0x000000 = 0
      data = [0x00, 0x00, 0x00].pack("C*")
      reader = described_class.new(data)
      
      result = reader.read_int24
      expect(result).to eq(0)
    end

    it "advances the position by 3 bytes" do
      data = [0x01, 0x02, 0x03, 0x04].pack("C*")
      reader = described_class.new(data)
      
      reader.read_int24
      expect(reader.data.pos).to eq(3)
    end

    it "handles middle-range values correctly" do
      # 0x123456 = 1193046
      data = [0x12, 0x34, 0x56].pack("C*")
      reader = described_class.new(data)
      
      result = reader.read_int24
      expect(result).to eq(0x123456)
    end
  end

  describe "#read_int16" do
    it "reads a 16-bit big-endian integer correctly" do
      # 0x0102 = 258 in decimal
      data = [0x01, 0x02].pack("C*")
      reader = described_class.new(data)
      
      result = reader.read_int16
      expect(result).to eq(0x0102)
      expect(result).to eq(258)
    end

    it "reads maximum 16-bit value correctly" do
      # 0xFFFF = 65535
      data = [0xFF, 0xFF].pack("C*")
      reader = described_class.new(data)
      
      result = reader.read_int16
      expect(result).to eq(0xFFFF)
      expect(result).to eq(65535)
    end

    it "reads minimum 16-bit value correctly" do
      # 0x0000 = 0
      data = [0x00, 0x00].pack("C*")
      reader = described_class.new(data)
      
      result = reader.read_int16
      expect(result).to eq(0)
    end

    it "advances the position by 2 bytes" do
      data = [0x01, 0x02, 0x03].pack("C*")
      reader = described_class.new(data)
      
      reader.read_int16
      expect(reader.data.pos).to eq(2)
    end

    it "handles middle-range values correctly" do
      # 0x1234 = 4660
      data = [0x12, 0x34].pack("C*")
      reader = described_class.new(data)
      
      result = reader.read_int16
      expect(result).to eq(0x1234)
    end
  end

  describe "#read_bytes" do
    let(:data) { "PATCH\x00\x01\x02\x03" }
    let(:reader) { described_class.new(data) }

    it "reads the specified number of bytes" do
      result = reader.read_bytes(4)
      expect(result).to eq("PATC")
      expect(result.bytesize).to eq(4)
    end

    it "reads binary bytes correctly" do
      reader.read_string(5) # Skip "PATCH"
      result = reader.read_bytes(3)
      expect(result).to eq("\x00\x01\x02")
    end

    it "advances the position correctly" do
      initial_pos = reader.data.pos
      reader.read_bytes(3)
      expect(reader.data.pos).to eq(initial_pos + 3)
    end

    it "can read single byte" do
      result = reader.read_bytes(1)
      expect(result).to eq("P")
      expect(result.bytesize).to eq(1)
    end
  end

  describe "#go_back" do
    let(:data) { "PATCH\x00\x01\x02" }
    let(:reader) { described_class.new(data) }

    it "moves the position backwards by specified bytes" do
      reader.read_string(5) # Position is now 5
      reader.go_back(2)
      expect(reader.data.pos).to eq(3)
    end

    it "allows reading again after going back" do
      first_read = reader.read_string(3)
      reader.go_back(3)
      second_read = reader.read_string(3)
      
      expect(first_read).to eq(second_read)
      expect(first_read).to eq("PAT")
    end

    it "can go back to the beginning" do
      reader.read_string(5)
      reader.go_back(5)
      expect(reader.data.pos).to eq(0)
    end

    it "works with multiple read operations" do
      reader.read_int16 # Reads 2 bytes, position is 2
      reader.read_bytes(1) # Reads 1 byte, position is 3
      reader.go_back(2) # Go back 2 bytes, position is 1
      
      result = reader.read_string(2)
      expect(result).to eq("AT")
    end
  end

  describe "integration with IPS patch format" do
    it "can read IPS header correctly" do
      patch_data = "PATCH\x00\x01\x02\x03EOF"
      reader = described_class.new(patch_data)
      
      header = reader.read_string(5)
      expect(header).to eq("PATCH")
    end

    it "can read IPS patch records correctly" do
      # Simulate an IPS record: offset (3 bytes), size (2 bytes), data
      # Offset: 0x000100 (256), Size: 0x0003 (3), Data: "ABC"
      patch_data = [
        0x00, 0x01, 0x00,  # offset: 256
        0x00, 0x03,         # size: 3
        0x41, 0x42, 0x43    # data: "ABC"
      ].pack("C*")
      
      reader = described_class.new(patch_data)
      
      offset = reader.read_int24
      size = reader.read_int16
      data = reader.read_bytes(size)
      
      expect(offset).to eq(256)
      expect(size).to eq(3)
      expect(data).to eq("ABC")
    end
  end
end
