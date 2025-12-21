#!/usr/bin/env node

/**
 * Postinstall script that runs the build in production environments
 * This ensures the TypeScript build happens even if Render only runs npm install
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Get the backend directory (parent of scripts directory)
const backendDir = path.resolve(__dirname, '..');
const distServerPath = path.join(backendDir, 'dist', 'server.js');
const distServerExists = fs.existsSync(distServerPath);
const isProduction = process.env.NODE_ENV === 'production';

if (isProduction && !distServerExists) {
  console.log('🔨 Production environment detected and dist/server.js not found');
  console.log('🔨 Running build...');
  try {
    execSync('npm run build', { 
      stdio: 'inherit', 
      cwd: backendDir,
      env: { ...process.env, NODE_ENV: 'production' }
    });
    
    // Verify build succeeded
    if (fs.existsSync(distServerPath)) {
      console.log('✅ Build completed successfully');
    } else {
      console.error('❌ Build completed but dist/server.js still not found');
      process.exit(1);
    }
  } catch (error) {
    console.error('❌ Build failed:', error.message);
    process.exit(1);
  }
} else if (isProduction && distServerExists) {
  console.log('✅ dist/server.js already exists, skipping build');
} else {
  console.log('ℹ️  Development environment, skipping production build');
}

