# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-01-27

### Changed
- **Refactoring**: Massive cleanup of `CONVERT.ps1` and all conversion modules
- **Architecture**: Created shared `scripts/utils.ps1` module for core logic
- **Logging**: Implemented central logging system (`logs/activity.log`)
- **UI**: Standardized headers and output messages across all tools

## [1.1.0] - 2026-01-27

### Added
- **Security**: Disk space check before processing large video files (>2GB)
- **UI**: Improved confirmation dialogs for critical actions
- **Audio**: Enhanced format selection hierarchy (Format > Codec > Quality)
- **Robustness**: Better input validation and error messages
- **Compatibility**: Updated FFmpeg parameters for wider codec support

## [1.0.0] - 2026-01-27

### Added
- Initial release
- **Image Conversion**: PNG, JPG, WEBP, GIF, ICO, PDF, BMP, TIFF
- **Image Compression**: 4 quality levels (95%, 85%, 70%, 50%)
- **Audio Conversion**: MP3, WAV, FLAC, AAC, OGG, M4A
- **Audio Compression**: 4 bitrate levels (320k, 192k, 128k, 64k)
- **Video Conversion**: MP4, AVI, MKV, WEBM, GIF, MOV
- **Video Compression**: 4 CRF levels with optional 720p downscale
- **Document Conversion**: PDF, DOCX, HTML, TXT, MD, EPUB, ODT
- Interactive menu system
- Automatic dependency installation (FFmpeg, ImageMagick, Pandoc)
- Real-time compression savings display
- Folder-based workflow (INPUT → OUTPUT)

### Technical
- PowerShell-based for Windows compatibility
- Uses winget for dependency management
- Modular script architecture
