<p align="center">
  <img src="assets/logo.svg" alt="File Converter Logo" width="120">
</p>

<h1 align="center">File Converter</h1>

<p align="center">
  <strong>A powerful, open-source file conversion and compression tool for Windows</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#supported-formats">Formats</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-Windows-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-5391FE?style=flat-square&logo=powershell&logoColor=white" alt="PowerShell">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License">
  <img src="https://img.shields.io/github/stars/nocodeboy/file-converter?style=flat-square" alt="Stars">
</p>

---

## 🌐 Web App

**No installation required. 100% private - files never leave your device.**

### **[Launch Web App](https://nocodeboy.github.io/file-converter/app/)**

Convert images, audio, and video directly in your browser using WebAssembly.

### Deploy en Cloudflare Workers (recomendado)

El repositorio ya incluye configuración lista para Workers (`wrangler.toml` + `worker.js`) para que FFmpeg funcione con `SharedArrayBuffer` en `/app`.

```bash
npm install -g wrangler
wrangler login
wrangler deploy
```

Después del deploy, abre `https://<tu-worker>.workers.dev/app/` y prueba conversión de audio/video.


[![Try Web App](https://img.shields.io/badge/Try%20Web%20App-Launch-06b6d4?style=for-the-badge)](https://nocodeboy.github.io/file-converter/app/)

---

## 🧩 Versions

This project includes two execution modes:

- **Web App (PWA)**: browser-based conversion at `/app` (ideal for quick use and sharing).
- **Local Windows CLI**: offline/local processing using `CONVERT.bat` and PowerShell scripts.

### Local executable (.exe) build (optional)

If you need a single executable launcher for Windows, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-exe.ps1
```

This generates `FileConverter.exe` (uses `ps2exe` under the hood).

## ✨ Features

- **�️ Image Conversion & Compression** - Convert between PNG, JPG, WEBP, GIF, ICO, BMP, TIFF and more
- **🎵 Audio Conversion & Compression** - Support for MP3, WAV, FLAC, AAC, OGG, M4A
- **🎬 Video Conversion & Compression** - Handle MP4, AVI, MKV, MOV, WEBM with quality presets
- **📄 Document Conversion** - Convert Markdown, HTML, DOCX, TXT, EPUB and more
- **📊 Smart Compression** - 4 quality levels with real-time size savings display
- **🚀 Simple Interface** - Easy-to-use interactive menu, no command line knowledge required
- **💯 100% Open Source** - Free forever, no hidden costs

## 📸 Screenshots

> **[View the interactive demo on our landing page](index.html)**

The tool features a clean, colorful terminal interface with an easy-to-navigate menu system.

## 📦 Installation

### Prerequisites

- Windows 10/11
- PowerShell 5.1 or higher (included in Windows)

### Quick Start

1. **Download** the latest release from [Releases](../../releases) or clone the repository:
   ```bash
   git clone https://github.com/nocodeboy/file-converter.git
   cd file-converter
   ```

2. **Install dependencies** (FFmpeg, ImageMagick, Pandoc):
   ```powershell
   # Right-click on install-dependencies.ps1 → Run with PowerShell
   # Or run in PowerShell:
   .\install-dependencies.ps1
   ```

3. **Restart** your terminal/PowerShell window

4. **Run** the converter:
   ```
   Double-click CONVERT.bat
   ```

## � Usage

### Basic Workflow

1. **Place files** in the appropriate `INPUT/` folder:
   - `INPUT/images/` for images
   - `INPUT/audio/` for audio files
   - `INPUT/video/` for videos
   - `INPUT/documents/` for documents

2. **Run** `CONVERT.bat`

3. **Select** file type and action:
   - `[C]` Convert - Change format
   - `[O]` Optimize - Compress/reduce size

4. **Find** your converted files in `OUTPUT/`

### Compression Levels

| Level | Images | Video (CRF) | Audio |
|-------|--------|-------------|-------|
| 1 - Maximum | 95% quality | CRF 18 | 320 kbps |
| 2 - High | 85% quality | CRF 23 | 192 kbps |
| 3 - Medium | 70% quality | CRF 28 | 128 kbps |
| 4 - Low | 50% quality | CRF 35 | 64 kbps |

## � Supported Formats

### Images
| Input | Output |
|-------|--------|
| JPG, JPEG, PNG, GIF, BMP, TIFF, WEBP, SVG, ICO, HEIC | PNG, JPG, WEBP, GIF, ICO, PDF, BMP, TIFF |

### Audio
| Input | Output |
|-------|--------|
| MP3, WAV, FLAC, AAC, OGG, M4A, WMA, AIFF, OPUS | MP3, WAV, FLAC, AAC, OGG, M4A |

### Video
| Input | Output |
|-------|--------|
| MP4, AVI, MKV, MOV, WMV, FLV, WEBM, M4V, MPEG, 3GP | MP4, AVI, MKV, WEBM, GIF, MOV, MP3 (audio only) |

### Documents
| Input | Output |
|-------|--------|
| MD, TXT, HTML, DOCX, RST, ORG, TEX, EPUB, ODT | PDF*, DOCX, HTML, TXT, MD, EPUB, ODT |

*PDF output requires LaTeX (MiKTeX or TeX Live)

## 📁 Project Structure

```
file-converter/
├── app/                        # Web App (PWA)
│   ├── index.html              # Main app UI
│   ├── manifest.json           # PWA manifest
│   ├── sw.js                   # Service Worker
│   ├── coi-serviceworker.js    # COOP/COEP headers
│   ├── css/app.css             # Styles
│   └── js/app.js               # Application logic
├── assets/                     # Visual assets
│   ├── logo.svg                # Project logo
│   └── favicon.svg             # Favicon
├── scripts/                    # CLI conversion modules
│   ├── utils.ps1               # Shared utilities & logging
│   ├── convert-*.ps1           # Conversion scripts
│   └── compress-*.ps1          # Compression scripts
├── INPUT/                      # Source files (CLI)
├── OUTPUT/                     # Converted files (CLI)
├── index.html                  # Landing page
├── CONVERT.bat                 # CLI entry point (Windows)
├── CONVERT.ps1                 # CLI main script
└── install-dependencies.ps1    # Dependency installer
```

## 🛠️ Dependencies

This project uses the following open-source tools:

| Tool | Purpose | License |
|------|---------|---------|
| [FFmpeg](https://ffmpeg.org/) | Audio & Video processing | LGPL/GPL |
| [ImageMagick](https://imagemagick.org/) | Image processing | Apache 2.0 |
| [Pandoc](https://pandoc.org/) | Document conversion | GPL |

All dependencies are installed automatically via `install-dependencies.ps1` using Windows Package Manager (winget).

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting a Pull Request.

### Development Setup

1. Fork the repository
2. Clone your fork
3. Create a feature branch: `git checkout -b feature/amazing-feature`
4. Make your changes
5. Test thoroughly
6. Commit: `git commit -m 'Add amazing feature'`
7. Push: `git push origin feature/amazing-feature`
8. Open a Pull Request

### Ideas for Contributions

- [ ] Add support for more formats
- [ ] Create a GUI version
- [ ] Add batch processing with progress bar
- [ ] Linux/macOS support
- [ ] Preset profiles (web, social media, archive)
- [ ] Drag & drop support

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Germán Huertas**
- Email: nocodeboy@gmail.com
- GitHub: [@nocodeboy](https://github.com/nocodeboy)

## 🙏 Acknowledgments

- [FFmpeg](https://ffmpeg.org/) team for the incredible multimedia framework
- [ImageMagick](https://imagemagick.org/) team for powerful image processing
- [Pandoc](https://pandoc.org/) team for universal document converter
- The open-source community for inspiration and support

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/nocodeboy">Germán Huertas</a>
</p>

<p align="center">
  <a href="https://github.com/nocodeboy/file-converter/stargazers">⭐ Star this project if you find it useful!</a>
</p>
