/*! coi-serviceworker v0.1.7 - Guido Zuidhof and contributors, licensed under MIT */
/*
 * This is the official coi-serviceworker that enables SharedArrayBuffer
 * on GitHub Pages by injecting the required COOP/COEP headers.
 */

// Check if we're in a ServiceWorker context
if (typeof window === 'undefined') {
    self.addEventListener("install", () => self.skipWaiting());
    self.addEventListener("activate", (e) => e.waitUntil(self.clients.claim()));

    self.addEventListener("fetch", function (e) {
        if (e.request.cache === "only-if-cached" && e.request.mode !== "same-origin") {
            return;
        }

        e.respondWith(
            fetch(e.request)
                .then((res) => {
                    if (res.status === 0) {
                        return res;
                    }

                    const newHeaders = new Headers(res.headers);
                    newHeaders.set("Cross-Origin-Embedder-Policy", "credentialless");
                    newHeaders.set("Cross-Origin-Opener-Policy", "same-origin");

                    return new Response(res.body, {
                        status: res.status,
                        statusText: res.statusText,
                        headers: newHeaders,
                    });
                })
                .catch((e) => console.error(e))
        );
    });

} else {
    // Window context
    (async function () {
        if (window.crossOriginIsolated !== false) return;

        const registration = await navigator.serviceWorker.register(window.document.currentScript.src).catch((e) =>
            console.error("COOP/COEP Service Worker failed to register:", e)
        );
        if (registration) {
            console.log("COOP/COEP Service Worker registered", registration.scope);

            registration.addEventListener("updatefound", () => {
                console.log("Reloading page to enable COOP/COEP...");
                window.location.reload();
            });

            if (registration.active && !navigator.serviceWorker.controller) {
                console.log("Reloading page to enable COOP/COEP...");
                window.location.reload();
            }
        }
    })();
}
