# Changelog

All notable changes to Structurize will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.0.0] - 2025-04-22

### Added

- **Dependency Analysis**: New `-a, --analyze` flag with options:
  - `deps`: Analyze file dependencies
  - `imports`: Focus on import statements
- **Graph Visualization**: Generate dependency graphs with `--graph` option:
  - `dot`: Output in GraphViz DOT format
  - `mermaid`: Output in Mermaid diagram format for Markdown
- **Cycle Detection**: Automatically identify circular dependencies
- **AI Integration**: Generate AI-ready prompt templates for architecture improvements
- **Language Support** for dependency detection:
  - JavaScript (ES6 imports, CommonJS require)
  - TypeScript (imports)
  - Python (import, from...import)
- **Enhanced JSON Schema** for dependency representation with nodes, edges, cycles, and stats
- **Documentation** for all new features and command line options

### Changed

- Updated JSON output format to support dependency data structure when using analyze mode
- Improved NDJSON format for more efficient AI processing
- Enhanced progress display during dependency analysis

### Fixed

- Fixed file extension detection for files without extensions
- Improved error handling for invalid analyze modes

## [3.9.2] - 2025-03-15

### Fixed

- Fixed BOM and CRLF handling in shell script execution
- Improved progress bar display on various terminal types
- Fixed escaping of special characters in file content

## [3.9.1] - 2025-03-01

### Added

- German error messages and tips for better accessibility

### Fixed

- Fixed empty file handling
- Improved metadata extraction reliability

## [3.9.0] - 2025-02-15

### Added

- Debug mode with `--debug` flag to show processed files
- Support for metadata export with `-m, --meta` flag
- Enhanced filtering with glob pattern support

### Changed

- Improved progress bar with percentage display
- Optimized file scanning for better performance

## [3.8.0] - 2025-02-01

### Added

- NDJSON output format for token-efficient AI preprocessing
- Shorthand `-n` flag for NDJSON output

### Changed

- Improved Markdown output formatting
- Enhanced text output for better readability

## [3.7.0] - 2025-01-15

### Added

- Initial public release
- Support for exporting in json, text, and markdown formats
- Directory filtering with `-s, --select`
- File type filtering with `-t, --types`
- Pattern exclusion with `-e, --exclude`
