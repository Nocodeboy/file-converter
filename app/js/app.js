/**
 * File Converter PWA
 * Browser-based file conversion using WebAssembly
 * Files never leave your device
 */

// ========================================
// State
// ========================================

const state = {
    files: [],
    convertedFiles: [],
    ffmpeg: null,
    ffmpegLoaded: false,
    ffmpegFailed: false,
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
// Utilities
// ========================================

function formatFileSize(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

function getFileType(file) {
    if (file.type.startsWith('image/')) return 'image';
    if (file.type.startsWith('audio/')) return 'audio';
    if (file.type.startsWith('video/')) return 'video';
    return 'unknown';
}

function getFileIcon(type) {
    switch (type) {
        case 'image': return '🖼️';
        case 'audio': return '🎵';
        case 'video': return '🎬';
        default: return '📄';
    }
}

function getFileExtension(filename) {
    return filename.split('.').pop().toLowerCase();
}

function replaceExtension(filename, newExt) {
    const base = filename.substring(0, filename.lastIndexOf('.'));
    return `${base}.${newExt}`;
}

// ========================================
// FFmpeg Loading (Lazy)
// ========================================

async function checkCrossOriginIsolated() {
    // Check if we have the required isolation for SharedArrayBuffer
    if (typeof crossOriginIsolated !== 'undefined' && crossOriginIsolated) {
        return true;
    }
    // Give the coi-serviceworker time to activate
    await new Promise(resolve => setTimeout(resolve, 100));
    return typeof crossOriginIsolated !== 'undefined' && crossOriginIsolated;
}

async function loadFFmpeg() {
    if (state.ffmpegLoaded) return true;
    if (state.ffmpegFailed) return false;

    try {
        showLoading('Checking browser compatibility...');

        // Check for SharedArrayBuffer support
        const isIsolated = await checkCrossOriginIsolated();
        if (!isIsolated) {
            console.warn('crossOriginIsolated is false, FFmpeg may not work');
            updateLoading('Enabling advanced features...');
            // Wait a bit more for service worker
            await new Promise(resolve => setTimeout(resolve, 500));
        }

        updateLoading('Loading FFmpeg library...');

        // Import FFmpeg from CDN with timeout
        const importPromise = Promise.all([
            import('https://unpkg.com/@ffmpeg/ffmpeg@0.12.7/dist/esm/index.js'),
            import('https://unpkg.com/@ffmpeg/util@0.12.1/dist/esm/index.js')
        ]);

        const timeoutPromise = new Promise((_, reject) =>
            setTimeout(() => reject(new Error('Timeout loading FFmpeg')), 30000)
        );

        const [{ FFmpeg }, { fetchFile, toBlobURL }] = await Promise.race([importPromise, timeoutPromise]);

        state.ffmpeg = new FFmpeg();
        state.fetchFile = fetchFile;

        state.ffmpeg.on('progress', ({ progress }) => {
            updateProgress(Math.round(progress * 100), 'Processing...');
        });

        state.ffmpeg.on('log', ({ message }) => {
            console.log('[FFmpeg]', message);
        });

        updateLoading('Loading FFmpeg core (this may take a moment)...');

        const baseURL = 'https://unpkg.com/@ffmpeg/core@0.12.6/dist/esm';

        const coreLoadPromise = state.ffmpeg.load({
            coreURL: await toBlobURL(`${baseURL}/ffmpeg-core.js`, 'text/javascript'),
            wasmURL: await toBlobURL(`${baseURL}/ffmpeg-core.wasm`, 'application/wasm')
        });

        const coreTimeoutPromise = new Promise((_, reject) =>
            setTimeout(() => reject(new Error('Timeout loading FFmpeg core')), 60000)
        );

        await Promise.race([coreLoadPromise, coreTimeoutPromise]);

        state.ffmpegLoaded = true;
        hideLoading();
        console.log('FFmpeg loaded successfully');
        return true;

    } catch (error) {
        console.error('Failed to load FFmpeg:', error);
        state.ffmpegFailed = true;
        hideLoading();

        let message = 'Failed to load FFmpeg for audio/video conversion.\n\n';
        if (error.message.includes('SharedArrayBuffer')) {
            message += 'Your browser does not support the required features.\n';
            message += 'Try using Chrome, Edge, or Firefox.\n\n';
            message += 'Image conversion still works!';
        } else if (error.message.includes('Timeout')) {
            message += 'The download timed out. Please check your internet connection and try again.';
        } else {
            message += 'Error: ' + error.message + '\n\n';
            message += 'Image conversion still works!';
        }

        alert(message);
        return false;
    }
}

// ========================================
// Image Conversion (Canvas API)
// ========================================

async function convertImage(file, format, quality) {
    return new Promise((resolve, reject) => {
        const img = new Image();
        const reader = new FileReader();

        reader.onload = (e) => {
            img.onload = () => {
                const canvas = document.createElement('canvas');
                canvas.width = img.width;
                canvas.height = img.height;

                const ctx = canvas.getContext('2d');
                ctx.drawImage(img, 0, 0);

                let mimeType;
                switch (format) {
                    case 'png': mimeType = 'image/png'; break;
                    case 'jpeg': mimeType = 'image/jpeg'; break;
                    case 'webp': mimeType = 'image/webp'; break;
                    case 'gif': mimeType = 'image/gif'; break;
                    default: mimeType = 'image/png';
                }

                canvas.toBlob(
                    (blob) => {
                        if (blob) {
                            resolve(blob);
                        } else {
                            reject(new Error('Failed to convert image'));
                        }
                    },
                    mimeType,
                    quality / 100
                );
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

async function convertMedia(file, format) {
    if (!state.ffmpegLoaded) {
        const loaded = await loadFFmpeg();
        if (!loaded) throw new Error('FFmpeg not available');
    }

    const ffmpeg = state.ffmpeg;
    const inputName = 'input' + getFileExtension(file.name);
    const outputName = `output.${format === 'gif-video' ? 'gif' : format}`;

    // Write input file
    await ffmpeg.writeFile(inputName, await state.fetchFile(file));

    // Build FFmpeg command based on format
    let args;
    switch (format) {
        case 'mp3':
            args = ['-i', inputName, '-vn', '-acodec', 'libmp3lame', '-q:a', '2', outputName];
            break;
        case 'wav':
            args = ['-i', inputName, '-vn', '-acodec', 'pcm_s16le', outputName];
            break;
        case 'ogg':
            args = ['-i', inputName, '-vn', '-acodec', 'libvorbis', '-q:a', '5', outputName];
            break;
        case 'mp4':
            args = ['-i', inputName, '-c:v', 'libx264', '-preset', 'fast', '-crf', '23', '-c:a', 'aac', outputName];
            break;
        case 'webm':
            args = ['-i', inputName, '-c:v', 'libvpx-vp9', '-crf', '30', '-b:v', '0', '-c:a', 'libopus', outputName];
            break;
        case 'gif-video':
            args = ['-i', inputName, '-vf', 'fps=10,scale=480:-1:flags=lanczos', '-loop', '0', outputName];
            break;
        default:
            throw new Error('Unsupported format: ' + format);
    }

    await ffmpeg.exec(args);

    // Read output file
    const data = await ffmpeg.readFile(outputName);

    // Cleanup
    await ffmpeg.deleteFile(inputName);
    await ffmpeg.deleteFile(outputName);

    // Determine mime type
    let mimeType;
    switch (format) {
        case 'mp3': mimeType = 'audio/mpeg'; break;
        case 'wav': mimeType = 'audio/wav'; break;
        case 'ogg': mimeType = 'audio/ogg'; break;
        case 'mp4': mimeType = 'video/mp4'; break;
        case 'webm': mimeType = 'video/webm'; break;
        case 'gif-video': mimeType = 'image/gif'; break;
        default: mimeType = 'application/octet-stream';
    }

    return new Blob([data.buffer], { type: mimeType });
}

// ========================================
// Conversion Handler
// ========================================

async function convertFiles() {
    if (state.isConverting || state.files.length === 0) return;

    state.isConverting = true;
    state.convertedFiles = [];

    const format = elements.outputFormat.value;
    const quality = parseInt(elements.quality.value);
    const isAudioVideo = ['mp3', 'wav', 'ogg', 'mp4', 'webm', 'gif-video'].includes(format);

    // Pre-load FFmpeg if needed
    if (isAudioVideo) {
        const loaded = await loadFFmpeg();
        if (!loaded) {
            state.isConverting = false;
            return;
        }
    }

    elements.progressContainer.hidden = false;
    elements.convertBtn.disabled = true;
    elements.results.hidden = true;

    for (let i = 0; i < state.files.length; i++) {
        const file = state.files[i];
        const fileType = getFileType(file);

        updateProgress(
            Math.round((i / state.files.length) * 100),
            `Converting ${i + 1} of ${state.files.length}: ${file.name}`
        );

        try {
            let blob;
            const actualFormat = format === 'gif-video' ? 'gif' : format;

            if (fileType === 'image' && ['png', 'jpeg', 'webp', 'gif'].includes(format)) {
                blob = await convertImage(file, format, quality);
            } else if (isAudioVideo) {
                blob = await convertMedia(file, format);
            } else {
                console.warn(`Cannot convert ${fileType} to ${format}`);
                continue;
            }

            const newName = replaceExtension(file.name, actualFormat);
            state.convertedFiles.push({
                name: newName,
                blob: blob,
                size: blob.size
            });

        } catch (error) {
            console.error(`Error converting ${file.name}:`, error);
        }
    }

    updateProgress(100, 'Done!');

    setTimeout(() => {
        elements.progressContainer.hidden = true;
        elements.convertBtn.disabled = false;
        state.isConverting = false;
        showResults();
    }, 500);
}

// ========================================
// UI Updates
// ========================================

function updateProgress(percent, text) {
    elements.progressFill.style.width = `${percent}%`;
    elements.progressText.textContent = text;
}

function showLoading(text) {
    elements.loadingOverlay.hidden = false;
    elements.loadingText.textContent = text;
}

function updateLoading(text) {
    elements.loadingText.textContent = text;
}

function hideLoading() {
    elements.loadingOverlay.hidden = true;
}

function renderFileList() {
    elements.fileList.innerHTML = state.files.map((file, index) => {
        const type = getFileType(file);
        return `
            <div class="file-item" data-index="${index}">
                <div class="file-icon ${type}">${getFileIcon(type)}</div>
                <div class="file-info">
                    <div class="file-name">${file.name}</div>
                    <div class="file-size">${formatFileSize(file.size)}</div>
                </div>
                <button class="file-remove" data-index="${index}">
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
            const index = parseInt(btn.dataset.index);
            state.files.splice(index, 1);
            updateUI();
        });
    });
}

function updateUI() {
    const hasFiles = state.files.length > 0;

    elements.dropzone.hidden = hasFiles;
    elements.panel.hidden = !hasFiles;

    if (hasFiles) {
        renderFileList();
        updateFormatOptions();
    }
}

function updateFormatOptions() {
    // Determine what type of files we have
    const types = new Set(state.files.map(f => getFileType(f)));
    const format = elements.outputFormat.value;

    // Show/hide quality slider based on format
    const imageFormats = ['png', 'jpeg', 'webp', 'gif'];
    elements.qualityGroup.hidden = !imageFormats.includes(format);
}

function showResults() {
    if (state.convertedFiles.length === 0) {
        alert('No files were converted successfully.');
        return;
    }

    elements.results.hidden = false;
    elements.resultList.innerHTML = state.convertedFiles.map((file, index) => `
        <div class="result-item">
            <div class="result-info">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M9 12l2 2 4-4"/>
                    <circle cx="12" cy="12" r="10"/>
                </svg>
                <span class="result-name">${file.name}</span>
                <span class="result-size">${formatFileSize(file.size)}</span>
            </div>
            <button class="result-download" data-index="${index}">Download</button>
        </div>
    `).join('');

    // Add download handlers
    elements.resultList.querySelectorAll('.result-download').forEach(btn => {
        btn.addEventListener('click', () => {
            const index = parseInt(btn.dataset.index);
            downloadFile(state.convertedFiles[index]);
        });
    });
}

function downloadFile(file) {
    const url = URL.createObjectURL(file.blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = file.name;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

function downloadAll() {
    state.convertedFiles.forEach(file => downloadFile(file));
}

function clearFiles() {
    state.files = [];
    state.convertedFiles = [];
    elements.results.hidden = true;
    updateUI();
}

// ========================================
// File Handling
// ========================================

function handleFiles(files) {
    const validFiles = Array.from(files).filter(file => {
        const type = getFileType(file);
        return type !== 'unknown';
    });

    if (validFiles.length === 0) {
        alert('No valid files selected. Please select images, audio, or video files.');
        return;
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
        handleFiles(e.target.files);
        e.target.value = ''; // Reset
    });

    // Drag & Drop
    elements.dropzone.addEventListener('dragover', (e) => {
        e.preventDefault();
        elements.dropzone.classList.add('dragover');
    });

    elements.dropzone.addEventListener('dragleave', (e) => {
        e.preventDefault();
        elements.dropzone.classList.remove('dragover');
    });

    elements.dropzone.addEventListener('drop', (e) => {
        e.preventDefault();
        elements.dropzone.classList.remove('dragover');
        handleFiles(e.dataTransfer.files);
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

    // Prevent drag on whole page
    document.addEventListener('dragover', (e) => e.preventDefault());
    document.addEventListener('drop', (e) => e.preventDefault());
}

// ========================================
// Service Worker Registration
// ========================================

async function registerServiceWorker() {
    if ('serviceWorker' in navigator) {
        try {
            await navigator.serviceWorker.register('sw.js');
            console.log('Service Worker registered');
        } catch (error) {
            console.log('Service Worker registration failed:', error);
        }
    }
}

// ========================================
// Initialize
// ========================================

function init() {
    initEventListeners();
    registerServiceWorker();
    console.log('File Converter PWA initialized');
}

// Start the app
init();
