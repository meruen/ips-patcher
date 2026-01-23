# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-01-23

### Added
- Optional `output` parameter to `Ips::Patcher.apply` method for specifying custom output file path

## [0.1.0] - 2026-01-20

### Added
- Initial release of ips-patcher gem
- `Ips::Patcher.apply` method for applying IPS patches to ROM files
- Support for standard IPS records (byte replacement at specific offsets)
- Support for RLE (Run-Length Encoding) records for efficient byte filling
- Automatic output filename generation (inserts `.patched` before file extension)
- Non-destructive patching (original ROM file remains unchanged)
- Comprehensive error handling with `Ips::Patcher::Error` exception class
- Binary reader and writer utilities for IPS format parsing
- Pure Ruby implementation with no external dependencies
- Full test coverage with RSpec
- YARD documentation support

### Features
- Validates IPS patch file format (checks for "PATCH" header)
- Processes patch records sequentially until "EOF" marker
- Handles both standard and RLE-compressed patch records
- Creates new patched ROM file without modifying the original

[0.1.1]: https://github.com/meruen/ips-patcher/releases/tag/v0.1.1
[0.1.0]: https://github.com/meruen/ips-patcher/releases/tag/v0.1.0
