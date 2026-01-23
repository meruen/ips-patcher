# frozen_string_literal: true

RSpec.describe Ips::Patcher do
  it "has a version number" do
    expect(Ips::Patcher::VERSION).not_to be nil
  end

  describe ".apply" do
    let(:rom_path) { File.join(__dir__, "..", "fixtures", "input.bin") }
    let(:patch_path) { File.join(__dir__, "..", "fixtures", "patch.ips") }
    let(:expected_path) { File.join(__dir__, "..", "fixtures", "output.bin") }
    let(:default_output_path) do
      File.join(
        __dir__, "..", "fixtures",
        "#{File.basename(rom_path, File.extname(rom_path))}.patched#{File.extname(rom_path)}"
      )
    end

    after do
      File.delete(default_output_path) if File.exist?(default_output_path)
      File.delete(custom_output_path) if defined?(custom_output_path) && File.exist?(custom_output_path)
    end

    context "when output path is not specified" do
      it "applies the patch and creates output with default naming" do
        Ips::Patcher.apply(rom_path, patch_path)

        expect(File.exist?(default_output_path)).to be true
      end

      it "produces byte-identical output to expected fixture" do
        Ips::Patcher.apply(rom_path, patch_path)

        actual_content = File.binread(default_output_path)
        expected_content = File.binread(expected_path)

        expect(actual_content).to eq(expected_content)
      end
    end

    context "when output path is specified" do
      let(:custom_output_path) { File.join(__dir__, "..", "fixtures", "custom_output.bin") }

      it "applies the patch and creates output at the specified path" do
        Ips::Patcher.apply(rom_path, patch_path, output: custom_output_path)

        expect(File.exist?(custom_output_path)).to be true
      end

      it "produces byte-identical output to expected fixture" do
        Ips::Patcher.apply(rom_path, patch_path, output: custom_output_path)

        actual_content = File.binread(custom_output_path)
        expected_content = File.binread(expected_path)

        expect(actual_content).to eq(expected_content)
      end

      it "does not create the default output file when custom path is provided" do
        Ips::Patcher.apply(rom_path, patch_path, output: custom_output_path)

        expect(File.exist?(default_output_path)).to be false
      end
    end
  end
end
