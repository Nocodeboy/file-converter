/*! coi-serviceworker v0.1.7 - Guido Zuidhof and contributors, licensed under MIT */
/*
 * Cross-Origin Isolation Service Worker
 *
 * This service worker enables SharedArrayBuffer support on hosts that don't
 * allow custom headers (like GitHub Pages) by intercepting responses and
 * adding the required COOP/COEP headers.
 *
 * Required for FFmpeg.wasm to work properly.
 */

let coepCredentialless = true;

if (typeof window === 'undefined') {
    // Service Worker context
    self.addEventListener("install", () => {
        self.skipWaiting();
    });

    self.addEventListener("activate", (event) => {
        event.waitUntil(self.clients.claim());
    });

    self.addEventListener("message", (event) => {
        if (event.data && event.data.type === "deregister") {
            self.registration.unregister().then(() => {
                return self.clients.matchAll();
            }).then((clients) => {
                clients.forEach((client) => client.navigate(client.url));
            });
        }
    });

    self.addEventListener("fetch", (event) => {
        const request = event.request;

        // Skip non-GET requests
        if (request.method !== "GET") {
            return;
        }

        // Skip chrome-extension and other non-http(s) requests
        if (!request.url.startsWith("http")) {
            return;
        }

        // Handle cache mode
        if (request.cache === "only-if-cached" && request.mode !== "same-origin") {
            return;
        }

        event.respondWith(
            fetch(request)
                .then((response) => {
                    // Don't modify opaque responses
                    if (response.status === 0) {
                        return response;
                    }

                    const newHeaders = new Headers(response.headers);

                    // Add COEP header
                    newHeaders.set(
                        "Cross-Origin-Embedder-Policy",
                        coepCredentialless ? "credentialless" : "require-corp"
                    );

                    // Add COOP header
                    newHeaders.set("Cross-Origin-Opener-Policy", "same-origin");

                    return new Response(response.body, {
                        status: response.status,
                        statusText: response.statusText,
                        headers: newHeaders,
                    });
                })
                .catch((error) => {
                    console.error("[COI-SW] Fetch error:", error);
                    throw error;
                })
        );
    });

} else {
    // Window context - register the service worker
    (() => {
        // Check if already isolated
        if (window.crossOriginIsolated) {
            console.log("[COI-SW] Already cross-origin isolated");
            return;
        }

        // Check if we already tried and reloaded
        const reloaded = window.sessionStorage.getItem("coi-sw-reloaded");
        if (reloaded) {
            window.sessionStorage.removeItem("coi-sw-reloaded");
            console.log("[COI-SW] Page was reloaded, isolation may not be possible");
            return;
        }

        // Only works in secure contexts
        if (!window.isSecureContext) {
            console.warn("[COI-SW] Not a secure context, cannot enable isolation");
            return;
        }

        // Check for service worker support
        if (!("serviceWorker" in navigator)) {
            console.warn("[COI-SW] Service Workers not supported");
            return;
        }

        // Get the script URL for registration
        const currentScript = document.currentScript;
        if (!currentScript) {
            console.warn("[COI-SW] Cannot determine script URL");
            return;
        }

        const scriptURL = currentScript.src;

        // Register the service worker
        navigator.serviceWorker
            .register(scriptURL)
            .then((registration) => {
                console.log("[COI-SW] Service Worker registered");

                // Handle new worker installation
                if (registration.installing) {
                    const worker = registration.installing;

                    worker.addEventListener("statechange", () => {
                        if (worker.state === "activated") {
                            console.log("[COI-SW] Service Worker activated, reloading...");
                            window.sessionStorage.setItem("coi-sw-reloaded", "true");
                            window.location.reload();
                        }
                    });
                } else if (registration.active && !navigator.serviceWorker.controller) {
                    // Service worker is active but not controlling the page
                    console.log("[COI-SW] Taking control, reloading...");
                    window.sessionStorage.setItem("coi-sw-reloaded", "true");
                    window.location.reload();
                }
            })
            .catch((error) => {
                console.error("[COI-SW] Registration failed:", error);
            });
    })();
}
