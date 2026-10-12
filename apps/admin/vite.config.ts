import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  base: '/admin/',
  plugins: [
    react({
      babel: {
        plugins: [['babel-plugin-react-compiler']],
      },
    }),
  ],
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost',
        changeOrigin: true,
        secure: false,
        ws: true,
        // Preserve all headers including Authorization
        configure: (proxy, _options) => {
          proxy.on('proxyReq', (proxyReq, req, _res) => {
            // Log incoming request details
            console.log(`[Proxy] ${req.method} ${req.url} -> http://localhost${req.url}`);

            // Explicitly copy all headers from the original request
            if (req.headers.authorization) {
              proxyReq.setHeader('Authorization', req.headers.authorization);
            }
            if (req.headers['content-type']) {
              proxyReq.setHeader('Content-Type', req.headers['content-type']);
            }
            if (req.headers.accept) {
              proxyReq.setHeader('Accept', req.headers.accept);
            }

            // Log if Authorization header is present
            if (req.headers.authorization) {
              console.log(`[Proxy] Authorization header found: ${req.headers.authorization.substring(0, 30)}...`);
            } else {
              console.warn(`[Proxy] No Authorization header in request`);
            }
          });
          proxy.on('proxyRes', (proxyRes, req, _res) => {
            console.log(`[Proxy] Response: ${proxyRes.statusCode} for ${req.method} ${req.url}`);
          });
          proxy.on('error', (err, _req, _res) => {
            console.error('[Proxy Error]', err);
          });
        },
      },
    },
  },
})
