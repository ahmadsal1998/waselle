import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
    },
  },
  server: {
    port: 3000,
  },
  build: {
    // Generate manifest for cache busting
    manifest: true,
    // Ensure unique filenames for cache busting
    rollupOptions: {
      output: {
        // Add hash to filenames for cache busting
        entryFileNames: 'assets/[name].[hash].js',
        chunkFileNames: 'assets/[name].[hash].js',
        assetFileNames: 'assets/[name].[hash].[ext]',
      },
    },
    // Clear output directory on each build
    emptyOutDir: true,
    // Copy delete-account.html to dist (Vite automatically copies public/ folder)
    copyPublicDir: true,
  },
  // Public directory - files here are copied to dist root during build
  publicDir: 'public',
});
