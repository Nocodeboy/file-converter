/**
 * File Converter PWA
 * Browser-based file conversion using WebAssembly
 * Files never leave your device
 *
 * @version 2.0.0
 * @license MIT
 */

'use strict';

// ========================================
// State
// ========================================

const state = {
    files: [],
    convertedFiles: [],
    ffmpeg: null,
    ffmpegLoaded: false,
    ffmpegFailed: false,
    ffmpegLoading: false,
    isConverting: false
};

// ========================================
// DOM Elements
// ========================================

const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => document.querySelectorAll(sel);

const elements = {
    dropzone: $('#dropzone'),
    fileInput: $('#fileInput'),
    panel: $('#panel'),
    fileList: $('#fileList'),
    outputFormat: $('#outputFormat'),
    quality: $('#quality'),
    qualityValue: $('#qualityValue'),
    qualityGroup: $('#qualityGroup'),
    progressContainer: $('#progressContainer'),
    progressFill: $('#progressFill'),
    progressText: $('#progressText'),
    convertBtn: $('#convertBtn'),
    clearBtn: $('#clearBtn'),
    results: $('#results'),
    resultList: $('#resultList'),
    downloadAllBtn: $('#downloadAllBtn'),
    loadingOverlay: $('#loadingOverlay'),
    loadingText: $('#loadingText')
};

// ========================================
// Constants
// ========================================

const FORMAT_CONFIG = {
    image: {
        formats: ['png', 'jpeg', 'webp', 'gif'],
        label: 'Images'
    },
    audio: {
        formats: ['mp3', 'wav', 'ogg'],
        label: 'Audio'
    },
    video: {
        formats: ['mp4', 'webm', 'gif-video'],
        label: 'Video'
    }
};

const FORMAT_LABELS = {
    png: 'PNG',
    jpeg: 'JPEG',
    webp: 'WebP',
    gif: 'GIF',
    mp3: 'MP3',
    wav: 'WAV',
    ogg: 'OGG',
    mp4: 'MP4',
    webm: 'WebM',
    'gif-video': 'GIF (animated)'
};

// ========================================
// Utilities
// ========================================

/**
 * Escape HTML to prevent XSS
 */
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

/**
 * Format file size to human readable
 */
function formatFileSize(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

/**
 * Get file type from MIME type
 */
function getFileType(file) {
    if (file.type.startsWith('image/')) return 'image';
    if (file.type.startsWith('audio/')) return 'audio';
    if (file.type.startsWith('video/')) return 'video';
    return 'unknown';
}

/**
 * Get icon for file type
 */
function getFileIcon(type) {
    const icons = {
        image: '🖼️',
        audio: '🎵',
        video: '🎬',
        unknown: '📄'
    };
    return icons[type] || icons.unknown;
}

/**
 * Get file extension
 */
function getFileExtension(filename) {
    const parts = filename.split('.');
    return parts.length > 1 ? parts.pop().toLowerCase() : '';
}

/**
 * Replace file extension
 */
function replaceExtension(filename, newExt) {
    const lastDot = filename.lastIndexOf('.');
    const base = lastDot > 0 ? filename.substring(0, lastDot) : filename;
    return `${base}.${newExt}`;
}

/**
 * Sleep utility
 */
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

// ========================================
// FFmpeg Loading
// ========================================

/**
 * Check if SharedArrayBuffer is available
 */
function checkSharedArrayBuffer() {
    try {
        new SharedArrayBuffer(1);
        return true;
    } catch (e) {
        return false;
    }
}

/**
 * Check cross-origin isolation status
 */
async function checkCrossOriginIsolated() {
    // Direct check
    if (window.crossOriginIsolated === true) {
        return true;
    }

    // Check SharedArrayBuffer availability
    if (checkSharedArrayBuffer()) {
        return true;
    }

    // Wait for service worker to activate
    await sleep(500);

    return window.crossOriginIsolated === true || checkSharedArrayBuffer();
}

/**
 * Load FFmpeg with proper error handling
 */
async function loadFFmpeg() {
    if (state.ffmpegLoaded) return true;
    if (state.ffmpegFailed) return false;
    if (state.ffmpegLoading) return false;

    // Quick check first - fail fast if SharedArrayBuffer is not available
    if (!window.crossOriginIsolated && !checkSharedArrayBuffer()) {
        state.ffmpegFailed = true;
        throw new Error('SharedArrayBuffer is not available');
    }

    state.ffmpegLoading = true;

    try {
        showLoading('Loading FFmpeg (this may take a moment)...');

        // Dynamic import with timeout
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 30000);

        const [ffmpegModule, utilModule] = await Promise.all([
            import('https://unpkg.com/@ffmpeg/ffmpeg@0.12.7/dist/esm/index.js'),
            import('https://unpkg.com/@ffmpeg/util@0.12.1/dist/esm/index.js')
        ]);

        clearTimeout(timeoutId);

        const { FFmpeg } = ffmpegModule;
        const { fetchFile, toBlobURL } = utilModule;

        state.ffmpeg = new FFmpeg();
        state.fetchFile = fetchFile;

        // Progress handler
        state.ffmpeg.on('progress', ({ progress }) => {
            const percent = Math.min(Math.round(progress * 100), 100);
            updateProgress(percent, `Processing... ${percent}%`);
        });

        // Log handler for debugging
        state.ffmpeg.on('log', ({ message }) => {
            console.debug('[FFmpeg]', message);
        });

        updateLoading('Downloading FFmpeg core (~30MB)...');

        const baseURL = 'https://unpkg.com/@ffmpeg/core@0.12.6/dist/esm';

        // Load with timeout
        const loadPromise = state.ffmpeg.load({
            coreURL: await toBlobURL(`${baseURL}/ffmpeg-core.js`, 'text/javascript'),
            wasmURL: await toBlobURL(`${baseURL}/ffmpeg-core.wasm`, 'application/wasm')
        });

        const loadTimeout = new Promise((_, reject) =>
            setTimeout(() => reject(new Error('FFmpeg load timeout')), 120000)
        );

        await Promise.race([loadPromise, loadTimeout]);

        state.ffmpegLoaded = true;
        state.ffmpegLoading = false;
        hideLoading();

        console.log('FFmpeg loaded successfully');
        return true;

    } catch (error) {
        console.error('FFmpeg load error:', error);
        state.ffmpegFailed = true;
        state.ffmpegLoading = false;
        hideLoading();

        const errorMessage = getFFmpegErrorMessage(error);
        showError(errorMessage);

        return false;
    }
}

/**
 * Get user-friendly error message for FFmpeg errors
 */
function getFFmpegErrorMessage(error) {
    const msg = error.message || String(error);

    if (msg.includes('SharedArrayBuffer') || !window.crossOriginIsolated) {
        return 'Audio/Video conversion is not available.\n\n' +
               'This is a browser security limitation on GitHub Pages.\n\n' +
               'What works:\n' +
               '✓ Image conversion (PNG, JPEG, WebP, GIF)\n\n' +
               'What doesn\'t work:\n' +
               '✗ Audio conversion (MP3, WAV, OGG)\n' +
               '✗ Video conversion (MP4, WebM)\n\n' +
               'To convert audio/video, download the CLI version from GitHub.';
    }

    if (msg.includes('timeout') || msg.includes('Timeout')) {
        return 'FFmpeg download timed out.\n\n' +
               'The FFmpeg library is about 30MB.\n' +
               'Please check your internet connection and try again.';
    }

    if (msg.includes('Failed to fetch') || msg.includes('NetworkError')) {
        return 'Could not download FFmpeg.\n\n' +
               'Please check your internet connection and try again.';
    }

    return `FFmpeg error: ${msg}\n\nImage conversion still works!`;
}

/**
 * Show error dialog
 */
function showError(message) {
    alert(message);
}

// ========================================
// Image Conversion (Canvas API)
// ========================================

/**
 * Convert image using Canvas API
 */
async function convertImage(file, format, quality) {
    return new Promise((resolve, reject) => {
        const img = new Image();
        const reader = new FileReader();

        reader.onload = (e) => {
            img.onload = () => {
                try {
                    const canvas = document.createElement('canvas');
                    canvas.width = img.naturalWidth || img.width;
                    canvas.height = img.naturalHeight || img.height;

                    const ctx = canvas.getContext('2d');

                    // White background for JPEG (no transparency)
                    if (format === 'jpeg') {
                        ctx.fillStyle = '#FFFFFF';
                        ctx.fillRect(0, 0, canvas.width, canvas.height);
                    }

                    ctx.drawImage(img, 0, 0);

                    const mimeTypes = {
                        png: 'image/png',
                        jpeg: 'image/jpeg',
                        webp: 'image/webp',
                        gif: 'image/gif'
                    };

                    const mimeType = mimeTypes[format] || 'image/png';
                    const qualityValue = format === 'png' ? undefined : quality / 100;

                    canvas.toBlob(
                        (blob) => {
                            if (blob) {
                                resolve(blob);
                            } else {
                                reject(new Error('Canvas conversion failed'));
                            }
                        },
                        mimeType,
                        qualityValue
                    );
                } catch (err) {
                    reject(err);
                }
            };

            img.onerror = () => reject(new Error('Failed to load image'));
            img.src = e.target.result;
        };

        reader.onerror = () => reject(new Error('Failed to read file'));
        reader.readAsDataURL(file);
    });
}

// ========================================
// Audio/Video Conversion (FFmpeg)
// ========================================

/**
 * Convert media file using FFmpeg
 */
async function convertMedia(file, format) {
    if (!state.ffmpegLoaded) {
        const loaded = await loadFFmpeg();
        if (!loaded) throw new Error('FFmpeg not available');
    }

    const ffmpeg = state.ffmpeg;
    const ext = getFileExtension(file.name) || 'tmp';
    const inputName = `input.${ext}`;
    const outputExt = format === 'gif-video' ? 'gif' : format;
    const outputName = `output.${outputExt}`;

    try {
        // Write input file
        const fileData = await state.fetchFile(file);
        await ffmpeg.writeFile(inputName, fileData);

        // Build FFmpeg arguments
        const args = getFFmpegArgs(inputName, outputName, format);

        // Execute conversion
        await ffmpeg.exec(args);

        // Read output file
        const data = await ffmpeg.readFile(outputName);

        // Cleanup
        try {
            await ffmpeg.deleteFile(inputName);
            await ffmpeg.deleteFile(outputName);
        } catch (e) {
            console.warn('Cleanup error:', e);
        }

        // Return blob
        const mimeTypes = {
            mp3: 'audio/mpeg',
            wav: 'audio/wav',
            ogg: 'audio/ogg',
            mp4: 'video/mp4',
            webm: 'video/webm',
            'gif-video': 'image/gif'
        };

        return new Blob([data.buffer], {
            type: mimeTypes[format] || 'application/octet-stream'
        });

    } catch (error) {
        // Cleanup on error
        try {
            await ffmpeg.deleteFile(inputName);
        } catch (e) {}

        throw error;
    }
}

/**
 * Get FFmpeg arguments for conversion
 */
function getFFmpegArgs(input, output, format) {
    const args = {
        mp3: ['-i', input, '-vn', '-acodec', 'libmp3lame', '-q:a', '2', output],
        wav: ['-i', input, '-vn', '-acodec', 'pcm_s16le', output],
        ogg: ['-i', input, '-vn', '-acodec', 'libvorbis', '-q:a', '5', output],
        mp4: ['-i', input, '-c:v', 'libx264', '-preset', 'fast', '-crf', '23', '-c:a', 'aac', '-movflags', '+faststart', output],
        webm: ['-i', input, '-c:v', 'libvpx-vp9', '-crf', '30', '-b:v', '0', '-c:a', 'libopus', output],
        'gif-video': ['-i', input, '-vf', 'fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse', '-loop', '0', output]
    };

    return args[format] || ['-i', input, output];
}

// ========================================
// Conversion Handler
// ========================================

/**
 * Main conversion function
 */
async function convertFiles() {
    if (state.isConverting || state.files.length === 0) return;

    const format = elements.outputFormat.value;
    const quality = parseInt(elements.quality.value, 10);
    const isMediaFormat = ['mp3', 'wav', 'ogg', 'mp4', 'webm', 'gif-video'].includes(format);

    // Pre-load FFmpeg if needed
    if (isMediaFormat) {
        const loaded = await loadFFmpeg();
        if (!loaded) return;
    }

    state.isConverting = true;
    state.convertedFiles = [];

    elements.progressContainer.hidden = false;
    elements.convertBtn.disabled = true;
    elements.results.hidden = true;

    const errors = [];

    for (let i = 0; i < state.files.length; i++) {
        const file = state.files[i];
        const fileType = getFileType(file);

        updateProgress(
            Math.round((i / state.files.length) * 100),
            `Converting ${i + 1}/${state.files.length}: ${escapeHtml(file.name)}`
        );

        try {
            let blob;
            const outputExt = format === 'gif-video' ? 'gif' : format;

            if (fileType === 'image' && FORMAT_CONFIG.image.formats.includes(format)) {
                blob = await convertImage(file, format, quality);
            } else if (isMediaFormat && (fileType === 'audio' || fileType === 'video')) {
                blob = await convertMedia(file, format);
            } else {
                errors.push(`${file.name}: Incompatible format`);
                continue;
            }

            state.convertedFiles.push({
                name: replaceExtension(file.name, outputExt),
                blob: blob,
                size: blob.size,
                originalSize: file.size
            });

        } catch (error) {
            console.error(`Error converting ${file.name}:`, error);
            errors.push(`${file.name}: ${error.message}`);
        }
    }

    updateProgress(100, 'Done!');

    await sleep(300);

    elements.progressContainer.hidden = true;
    elements.convertBtn.disabled = false;
    state.isConverting = false;

    if (errors.length > 0) {
        console.warn('Conversion errors:', errors);
    }

    showResults();
}

// ========================================
// UI Functions
// ========================================

function updateProgress(percent, text) {
    elements.progressFill.style.width = `${percent}%`;
    elements.progressText.textContent = text;
}

function showLoading(text) {
    elements.loadingOverlay.hidden = false;
    elements.loadingOverlay.style.display = '';
    elements.loadingText.textContent = text;
}

function updateLoading(text) {
    elements.loadingText.textContent = text;
}

function hideLoading() {
    elements.loadingOverlay.hidden = true;
    elements.loadingOverlay.style.display = 'none';
}

/**
 * Render file list with proper escaping
 */
function renderFileList() {
    elements.fileList.innerHTML = state.files.map((file, index) => {
        const type = getFileType(file);
        const name = escapeHtml(file.name);
        const size = formatFileSize(file.size);

        return `
            <div class="file-item" data-index="${index}">
                <div class="file-icon ${type}">${getFileIcon(type)}</div>
                <div class="file-info">
                    <div class="file-name" title="${name}">${name}</div>
                    <div class="file-size">${size}</div>
                </div>
                <button class="file-remove" data-index="${index}" aria-label="Remove file">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M18 6L6 18M6 6l12 12"/>
                    </svg>
                </button>
            </div>
        `;
    }).join('');

    // Add remove handlers
    elements.fileList.querySelectorAll('.file-remove').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const index = parseInt(btn.dataset.index, 10);
            state.files.splice(index, 1);
            updateUI();
        });
    });
}

/**
 * Update format selector based on file types
 */
function updateFormatSelector() {
    const types = new Set(state.files.map(f => getFileType(f)));
    const select = elements.outputFormat;

    // Build new options
    let html = '';

    for (const [type, config] of Object.entries(FORMAT_CONFIG)) {
        if (types.has(type)) {
            html += `<optgroup label="${config.label}">`;
            for (const format of config.formats) {
                html += `<option value="${format}">${FORMAT_LABELS[format]}</option>`;
            }
            html += '</optgroup>';
        }
    }

    // Update if changed
    if (select.innerHTML !== html) {
        const previousValue = select.value;
        select.innerHTML = html;

        // Try to restore previous selection
        if ([...select.options].some(o => o.value === previousValue)) {
            select.value = previousValue;
        }
    }

    updateFormatOptions();
}

/**
 * Update quality slider visibility
 */
function updateFormatOptions() {
    const format = elements.outputFormat.value;
    const imageFormats = FORMAT_CONFIG.image.formats;
    elements.qualityGroup.hidden = !imageFormats.includes(format);
}

function updateUI() {
    const hasFiles = state.files.length > 0;

    elements.dropzone.hidden = hasFiles;
    elements.panel.hidden = !hasFiles;

    if (hasFiles) {
        renderFileList();
        updateFormatSelector();
    }
}

/**
 * Show conversion results
 */
function showResults() {
    if (state.convertedFiles.length === 0) {
        showError('No files were converted. Please check the file formats.');
        return;
    }

    elements.results.hidden = false;

    const totalSaved = state.convertedFiles.reduce((acc, f) => {
        return acc + Math.max(0, f.originalSize - f.size);
    }, 0);

    elements.resultList.innerHTML = state.convertedFiles.map((file, index) => {
        const name = escapeHtml(file.name);
        const size = formatFileSize(file.size);
        const savings = file.originalSize > file.size
            ? `(${Math.round((1 - file.size / file.originalSize) * 100)}% smaller)`
            : '';

        return `
            <div class="result-item">
                <div class="result-info">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M9 12l2 2 4-4"/>
                        <circle cx="12" cy="12" r="10"/>
                    </svg>
                    <span class="result-name" title="${name}">${name}</span>
                    <span class="result-size">${size} ${savings}</span>
                </div>
                <button class="result-download" data-index="${index}">Download</button>
            </div>
        `;
    }).join('');

    // Add download handlers
    elements.resultList.querySelectorAll('.result-download').forEach(btn => {
        btn.addEventListener('click', () => {
            const index = parseInt(btn.dataset.index, 10);
            downloadFile(state.convertedFiles[index]);
        });
    });
}

/**
 * Download a single file
 */
function downloadFile(file) {
    const url = URL.createObjectURL(file.blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = file.name;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);

    // Revoke after a short delay
    setTimeout(() => URL.revokeObjectURL(url), 1000);
}

/**
 * Download all files as ZIP
 */
async function downloadAll() {
    if (state.convertedFiles.length === 0) return;

    // If only one file, download directly
    if (state.convertedFiles.length === 1) {
        downloadFile(state.convertedFiles[0]);
        return;
    }

    try {
        // Show loading
        showLoading('Creating ZIP file...');

        // Dynamically import JSZip
        const JSZip = (await import('https://unpkg.com/jszip@3.10.1/dist/jszip.min.js')).default
            || window.JSZip;

        // If JSZip didn't load properly, try loading it via script
        if (!JSZip) {
            await loadJSZipFallback();
        }

        const zip = new (JSZip || window.JSZip)();

        // Add all files to ZIP
        state.convertedFiles.forEach((file, index) => {
            // Handle duplicate names by adding index
            let filename = file.name;
            const existingNames = state.convertedFiles.slice(0, index).map(f => f.name);
            if (existingNames.includes(filename)) {
                const ext = filename.split('.').pop();
                const base = filename.slice(0, -(ext.length + 1));
                filename = `${base}_${index}.${ext}`;
            }
            zip.file(filename, file.blob);
        });

        updateLoading('Compressing files...');

        // Generate ZIP
        const zipBlob = await zip.generateAsync({
            type: 'blob',
            compression: 'DEFLATE',
            compressionOptions: { level: 6 }
        }, (metadata) => {
            updateLoading(`Compressing... ${Math.round(metadata.percent)}%`);
        });

        hideLoading();

        // Download ZIP
        const url = URL.createObjectURL(zipBlob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `converted-files-${Date.now()}.zip`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        setTimeout(() => URL.revokeObjectURL(url), 1000);

    } catch (error) {
        console.error('ZIP creation failed:', error);
        hideLoading();

        // Fallback: download files individually
        console.log('Falling back to individual downloads');
        state.convertedFiles.forEach((file, index) => {
            setTimeout(() => downloadFile(file), index * 200);
        });
    }
}

/**
 * Fallback loader for JSZip
 */
function loadJSZipFallback() {
    return new Promise((resolve, reject) => {
        if (window.JSZip) {
            resolve();
            return;
        }
        const script = document.createElement('script');
        script.src = 'https://unpkg.com/jszip@3.10.1/dist/jszip.min.js';
        script.onload = resolve;
        script.onerror = reject;
        document.head.appendChild(script);
    });
}

/**
 * Clear all files
 */
function clearFiles() {
    state.files = [];
    state.convertedFiles = [];
    elements.results.hidden = true;
    updateUI();
}

// ========================================
// File Handling
// ========================================

/**
 * Handle dropped/selected files
 */
function handleFiles(fileList) {
    const files = Array.from(fileList);

    const validFiles = files.filter(file => {
        const type = getFileType(file);
        return type !== 'unknown';
    });

    const invalidCount = files.length - validFiles.length;

    if (validFiles.length === 0) {
        showError('No valid files selected.\n\nSupported formats:\n• Images (PNG, JPG, WebP, GIF, etc.)\n• Audio (MP3, WAV, OGG, etc.)\n• Video (MP4, WebM, MOV, etc.)');
        return;
    }

    if (invalidCount > 0) {
        console.warn(`${invalidCount} unsupported file(s) skipped`);
    }

    state.files = [...state.files, ...validFiles];
    updateUI();
}

// ========================================
// Event Listeners
// ========================================

function initEventListeners() {
    // Dropzone click
    elements.dropzone.addEventListener('click', () => {
        elements.fileInput.click();
    });

    // File input change
    elements.fileInput.addEventListener('change', (e) => {
        if (e.target.files.length > 0) {
            handleFiles(e.target.files);
        }
        e.target.value = '';
    });

    // Drag & Drop
    elements.dropzone.addEventListener('dragover', (e) => {
        e.preventDefault();
        e.stopPropagation();
        elements.dropzone.classList.add('dragover');
    });

    elements.dropzone.addEventListener('dragleave', (e) => {
        e.preventDefault();
        e.stopPropagation();
        elements.dropzone.classList.remove('dragover');
    });

    elements.dropzone.addEventListener('drop', (e) => {
        e.preventDefault();
        e.stopPropagation();
        elements.dropzone.classList.remove('dragover');

        if (e.dataTransfer.files.length > 0) {
            handleFiles(e.dataTransfer.files);
        }
    });

    // Quality slider
    elements.quality.addEventListener('input', (e) => {
        elements.qualityValue.textContent = `${e.target.value}%`;
    });

    // Format change
    elements.outputFormat.addEventListener('change', updateFormatOptions);

    // Buttons
    elements.convertBtn.addEventListener('click', convertFiles);
    elements.clearBtn.addEventListener('click', clearFiles);
    elements.downloadAllBtn.addEventListener('click', downloadAll);

    // Prevent default drag behavior on document
    document.addEventListener('dragover', (e) => e.preventDefault());
    document.addEventListener('drop', (e) => e.preventDefault());

    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => {
        // Ctrl/Cmd + V to paste files (if supported)
        if ((e.ctrlKey || e.metaKey) && e.key === 'v') {
            // Paste handling would go here
        }
    });
}

// ========================================
// Service Worker
// ========================================

async function registerServiceWorker() {
    if ('serviceWorker' in navigator) {
        try {
            const registration = await navigator.serviceWorker.register('sw.js');
            console.log('Service Worker registered:', registration.scope);
        } catch (error) {
            console.warn('Service Worker registration failed:', error);
        }
    }
}

// ========================================
// Initialize
// ========================================

function init() {
    // Ensure loading overlay is hidden on startup
    hideLoading();

    // Check for required features
    if (!window.Promise || !window.fetch) {
        showError('Your browser is not supported. Please use a modern browser.');
        return;
    }

    initEventListeners();
    registerServiceWorker();

    console.log('File Converter PWA v2.2.0 initialized');
}

// Start app when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
