# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-04-16

### Added
- Processing instruction (PI) node support via `Document#processing_instruction` / `#pi`

## [0.3.0] - 2026-04-10

### Added
- Add `declaration:` option to `build`, `build_soap`, and `Document.new` to omit the XML declaration when building fragments
- Add CDATA content validation — raises `Error` if content contains `]]>`
- Add comment text validation — raises `Error` if text contains `--`
- Add Ruby 3.4 to CI test matrix

## [0.2.2] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.2.1] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.2.0] - 2026-03-28

### Added

- XML namespace support with `namespace` and `namespace_tag` methods for prefix declarations and namespace-aware elements
- SOAP envelope builder with `soap_envelope` DSL and `build_soap` convenience method supporting SOAP 1.1 and 1.2
- XML fragment composition with `append` (merge Document objects) and `insert_fragment` (insert raw XML strings)
- Support for double-underscore to colon conversion in symbol attribute keys (e.g. `xmlns__soap:` becomes `xmlns:soap=`)

## [0.1.1] - 2026-03-26

### Added

- Add GitHub funding configuration

## [0.1.0] - 2026-03-26

### Added
- Initial release
- Block-based DSL for building XML documents
- XML declaration with configurable version and encoding
- Element creation with attributes via `tag` method
- Escaped text content via `text` method
- CDATA sections via `cdata` method
- XML comments via `comment` method
- Processing instructions via `processing_instruction` method
- Raw XML insertion via `raw` method
- method_missing DSL for natural element creation
- Pretty printing with configurable indentation via `to_xml(indent:)`
- XML entity escaping for all five standard entities (&, <, >, ", ')
