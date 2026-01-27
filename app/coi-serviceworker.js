/*! coi-serviceworker v0.1.7 - Guido Zuidhof and contributors, licensed under MIT */
/*
 * This Service Worker adds the required COOP/COEP headers to enable SharedArrayBuffer
 * which is required by FFmpeg.wasm for multi-threaded processing.
 *
 * GitHub Pages doesn't allow custom headers, so this SW intercepts requests
 * and adds the necessary headers to responses.
 */

let coepCredentialless = false;
if (typeof window === 'undefined') {
    self.addEventListener("install", () => self.skipWaiting());
    self.addEventListener("activate", (e) => e.waitUntil(self.clients.claim()));

    self.addEventListener("message", (ev) => {
        if (!ev.data) {
            return;
        } else if (ev.data.type === "deregister") {
            self.registration
                .unregister()
                .then(() => {
                    return self.clients.matchAll();
                })
                .then((clients) => {
                    clients.forEach((client) => client.navigate(client.url));
                });
        } else if (ev.data.type === "coepCredentialless") {
            coepCredentialless = ev.data.value;
        }
    });

    self.addEventListener("fetch", function (event) {
        const r = event.request;
        if (r.cache === "only-if-cached" && r.mode !== "same-origin") {
            return;
        }

        const request = (coepCredentialless && r.mode === "no-cors")
            ? new Request(r, {
                credentials: "omit",
            })
            : r;

        event.respondWith(
            fetch(request)
                .then((response) => {
                    if (response.status === 0) {
                        return response;
                    }

                    const newHeaders = new Headers(response.headers);
                    newHeaders.set("Cross-Origin-Embedder-Policy",
                        coepCredentialless ? "credentialless" : "require-corp"
                    );
                    newHeaders.set("Cross-Origin-Opener-Policy", "same-origin");

                    return new Response(response.body, {
                        status: response.status,
                        statusText: response.statusText,
                        headers: newHeaders,
                    });
                })
                .catch((e) => console.error(e))
        );
    });

} else {
    (() => {
        const reloadedBySelf = window.sessionStorage.getItem("coiReloadedBySelf");
        window.sessionStorage.removeItem("coiReloadedBySelf");
        const coepDegrading = (reloadedBySelf === "coepdegrade");

        // Check if already works
        if (window.crossOriginIsolated !== false || reloadedBySelf) {
            return;
        }

        // Check if can be fixed via credentialless
        if (!reloadedBySelf && window.isSecureContext &&
            !isLocalhost() &&
            typeof Response !== 'undefined' &&
            typeof Response.prototype.clone === 'function') {

            // Check for credentialless support
            if (window.navigator && 'credentials' in window.navigator) {
                coepCredentialless = true;
            }
        }

        // If localhost or file://, COOP/COEP won't work anyway
        function isLocalhost() {
            return window.location.hostname === 'localhost' ||
                   window.location.hostname === '127.0.0.1' ||
                   window.location.hostname === '';
        }

        if (!window.isSecureContext) {
            console.log("COOP/COEP Service Worker: Not a secure context, cannot register.");
            return;
        }

        // Register the service worker
        navigator.serviceWorker
            .register(window.document.currentScript.src)
            .then(
                (registration) => {
                    registration.addEventListener("updatefound", () => {
                        const worker = registration.installing;
                        worker.addEventListener("statechange", () => {
                            if (worker.state === "activated") {
                                window.sessionStorage.setItem("coiReloadedBySelf", coepDegrading ? "coepdegrade" : "reload");
                                window.location.reload();
                            }
                        });
                    });

                    if (registration.active && !navigator.serviceWorker.controller) {
                        window.sessionStorage.setItem("coiReloadedBySelf", coepDegrading ? "coepdegrade" : "reload");
                        window.location.reload();
                    }
                },
                (err) => {
                    console.error("COOP/COEP Service Worker failed to register:", err);
                }
            );
    })();
}
