/**
 * File Converter PWA - Service Worker
 * Enables offline functionality and caching
 */

const CACHE_NAME = 'file-converter-v9';

// Get the base path dynamically (works with GitHub Pages subdirectories)
const BASE_PATH = self.registration.scope;

// Assets to cache (relative to service worker location)
const STATIC_ASSETS = [
    './',
    './index.html',
    './css/app.css',
    './js/app.js',
    './manifest.json',
    '../assets/favicon.svg',
    '../assets/logo.svg'
];

// External resources to cache
const EXTERNAL_ASSETS = [
    'https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap'
];

// Install event - cache static assets
self.addEventListener('install', (event) => {
    console.log('[SW] Installing...');
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => {
                console.log('[SW] Caching static assets');
                // Cache assets with relative URLs resolved to absolute
                const urlsToCache = STATIC_ASSETS.map(asset => new URL(asset, self.location.href).href);
                return cache.addAll(urlsToCache);
            })
            .then(() => self.skipWaiting())
            .catch(err => {
                console.log('[SW] Cache failed:', err);
            })
    );
});

// Activate event - clean old caches
self.addEventListener('activate', (event) => {
    console.log('[SW] Activating...');
    event.waitUntil(
        caches.keys()
            .then((cacheNames) => {
                return Promise.all(
                    cacheNames
                        .filter((name) => name.startsWith('file-converter-') && name !== CACHE_NAME)
                        .map((name) => {
                            console.log('[SW] Deleting old cache:', name);
                            return caches.delete(name);
                        })
                );
            })
            .then(() => self.clients.claim())
    );
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
    const { request } = event;
    const url = new URL(request.url);

    // Skip non-GET requests
    if (request.method !== 'GET') return;

    // Skip FFmpeg WASM files (they're large and should be fetched fresh)
    if (url.href.includes('ffmpeg') || url.href.includes('.wasm')) {
        return;
    }

    // Skip chrome-extension and other non-http(s) requests
    if (!url.protocol.startsWith('http')) {
        return;
    }

    event.respondWith(
        caches.match(request)
            .then((cachedResponse) => {
                if (cachedResponse) {
                    return cachedResponse;
                }

                return fetch(request)
                    .then((networkResponse) => {
                        if (!networkResponse || networkResponse.status !== 200) {
                            return networkResponse;
                        }

                        // Cache successful responses for same-origin assets
                        if (url.origin === self.location.origin) {
                            const responseToCache = networkResponse.clone();
                            caches.open(CACHE_NAME)
                                .then((cache) => {
                                    cache.put(request, responseToCache);
                                });
                        }

                        return networkResponse;
                    })
                    .catch(() => {
                        // Offline fallback for navigation requests
                        if (request.mode === 'navigate') {
                            return caches.match(new URL('./index.html', self.location.href).href);
                        }
                        return new Response('Offline', { status: 503 });
                    });
            })
    );
});

// Handle messages from the main thread
self.addEventListener('message', (event) => {
    if (event.data === 'skipWaiting') {
        self.skipWaiting();
    }
});

console.log('[SW] Service Worker loaded');
