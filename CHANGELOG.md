# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.1] - 2026-01-28

### Fixed
- **Critical**: Fixed FFmpeg input filename bug (missing dot before extension)
- **Security**: Added XSS protection by escaping file names in HTML output
- **UX**: Format selector now filters options based on uploaded file types
- **Reliability**: Improved coi-serviceworker with better error handling and logging
- **Performance**: Added loading state to prevent duplicate FFmpeg loads
- **Compatibility**: Better SharedArrayBuffer detection with fallback checks

### Improved
- Enhanced error messages with actionable troubleshooting steps
- Added timeout handling for FFmpeg downloads (30s library, 120s core)
- JPEG conversion now adds white background (handles transparency properly)
- GIF conversion uses palette optimization for better quality
- MP4 output includes faststart flag for web streaming
- Results now show file size savings percentage

### Technical
- Refactored app.js with proper JSDoc documentation
- Added `'use strict'` mode for better error catching
- Improved memory management with URL.revokeObjectURL cleanup
- Added aria-labels for accessibility

## [2.0.0] - 2026-01-27

### Added
- **Web App**: Browser-based PWA for file conversion (no installation required)
- **Privacy**: All processing happens locally in the browser - files never leave the device
- **Image Conversion**: Using Canvas API (PNG, JPEG, WebP, GIF)
- **Audio/Video Conversion**: Using FFmpeg.wasm (MP3, WAV, OGG, MP4, WebM, GIF)
- **Landing Page**: Modern Awwwards-level design with dark mode
- **Visual Identity**: New SVG logo and favicon with gradient design
- **Offline Support**: Service Worker for PWA functionality
- **GitHub Pages**: Configured for static hosting with COOP/COEP headers

### Technical
- FFmpeg.wasm for browser-based audio/video processing
- Canvas API for zero-dependency image conversion
- coi-serviceworker for SharedArrayBuffer support on GitHub Pages
- Drag & drop file upload with quality slider
- Responsive design for mobile devices

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
