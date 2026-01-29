/*! coi-serviceworker v0.1.7 - Guido Zuidhof and contributors, licensed under MIT */
/*
 * Cross-Origin Isolation Service Worker
 *
 * - On Cloudflare Pages: Headers set via _headers file, SW not needed
 * - On GitHub Pages: SW injects COOP/COEP headers
 */

if (typeof window === 'undefined') {
    // Service Worker context
    self.addEventListener("install", () => self.skipWaiting());
    self.addEventListener("activate", (e) => e.waitUntil(self.clients.claim()));

    self.addEventListener("fetch", function (e) {
        if (e.request.cache === "only-if-cached" && e.request.mode !== "same-origin") {
            return;
        }

        e.respondWith(
            fetch(e.request)
                .then((res) => {
                    if (res.status === 0) return res;

                    const newHeaders = new Headers(res.headers);
                    newHeaders.set("Cross-Origin-Embedder-Policy", "credentialless");
                    newHeaders.set("Cross-Origin-Opener-Policy", "same-origin");

                    return new Response(res.body, {
                        status: res.status,
                        statusText: res.statusText,
                        headers: newHeaders,
                    });
                })
                .catch((err) => {
                    console.error("[COI-SW] Fetch error:", err);
                    throw err;
                })
        );
    });

} else {
    // Window context
    (async function () {
        // Already isolated? Great, nothing to do (Cloudflare Pages with native headers)
        if (window.crossOriginIsolated) {
            console.log("[COI] Cross-origin isolated via native headers");
            return;
        }

        // No service worker support
        if (!navigator.serviceWorker) {
            console.warn("[COI] Service Workers not supported");
            return;
        }

        try {
            const registration = await navigator.serviceWorker.register(
                window.document.currentScript.src
            );

            console.log("[COI] Service Worker registered:", registration.scope);

            registration.addEventListener("updatefound", () => {
                console.log("[COI] Reloading to enable COOP/COEP...");
                window.location.reload();
            });

            if (registration.active && !navigator.serviceWorker.controller) {
                console.log("[COI] Reloading to enable COOP/COEP...");
                window.location.reload();
            }
        } catch (e) {
            console.error("[COI] Registration failed:", e);
        }
    })();
}
