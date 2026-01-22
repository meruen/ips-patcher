# frozen_string_literal: true

RSpec.describe Ips::Patcher do
  it "has a version number" do
    expect(Ips::Patcher::VERSION).not_to be nil
  end

  describe ".apply" do
    let(:rom_path) { File.join(__dir__, "..", "fixtures", "input.bin") }
    let(:patch_path) { File.join(__dir__, "..", "fixtures", "patch.ips") }
    let(:expected_path) { File.join(__dir__, "..", "fixtures", "output.bin") }
    let(:output_path) { File.basename(rom_path) + ".patched.#{File.extname(rom_path)}" }

    after do
      File.delete(output_path) if File.exist?(output_path)
    end

    it "applies the patch and produces byte-identical output" do
      Ips::Patcher.apply(rom_path, patch_path)

      expect(File.exist?(output_path)).to be true

      actual_content = File.binread(output_path)
      expected_content = File.binread(expected_path)

      expect(actual_content).to eq(expected_content)
    end
  end
end
