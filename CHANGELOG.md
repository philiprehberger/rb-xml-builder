# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
