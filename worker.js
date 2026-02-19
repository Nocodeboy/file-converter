/**
 * Cloudflare Worker entrypoint for File Converter.
 *
 * Responsibilities:
 * - Serve static files through the ASSETS binding.
 * - Add COOP/COEP headers for /app routes so FFmpeg.wasm can use SharedArrayBuffer.
 * - Add baseline security headers for all responses.
 */

const APP_PATH_PREFIX = '/app';

function addSecurityHeaders(headers) {
  headers.set('X-Content-Type-Options', 'nosniff');
  headers.set('X-Frame-Options', 'DENY');
  headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  return headers;
}

function addIsolationHeaders(headers) {
  headers.set('Cross-Origin-Opener-Policy', 'same-origin');
  headers.set('Cross-Origin-Embedder-Policy', 'credentialless');
  headers.set('Cross-Origin-Resource-Policy', 'cross-origin');
  return headers;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/healthz') {
      return new Response('ok', {
        headers: {
          'Content-Type': 'text/plain; charset=utf-8',
          'Cache-Control': 'no-store'
        }
      });
    }

    const assetResponse = await env.ASSETS.fetch(request);
    const headers = new Headers(assetResponse.headers);

    addSecurityHeaders(headers);

    if (url.pathname === APP_PATH_PREFIX || url.pathname.startsWith(`${APP_PATH_PREFIX}/`)) {
      addIsolationHeaders(headers);
    }

    return new Response(assetResponse.body, {
      status: assetResponse.status,
      statusText: assetResponse.statusText,
      headers
    });
  }
};
