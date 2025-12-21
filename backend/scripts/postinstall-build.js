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
  
  // Check if TypeScript and type definitions are available (needed for build)
  const typescriptPath = path.join(backendDir, 'node_modules', '.bin', 'tsc');
  const typesBcryptjsPath = path.join(backendDir, 'node_modules', '@types', 'bcryptjs');
  const typescriptExists = fs.existsSync(typescriptPath);
  const typesExist = fs.existsSync(typesBcryptjsPath);
  
  if (!typescriptExists || !typesExist) {
    console.log('📦 DevDependencies missing, installing...');
    try {
      // Install devDependencies by running npm install without --production flag
      // This ensures TypeScript and @types packages are available for the build
      const installEnv = { ...process.env };
      delete installEnv.npm_config_production; // Remove production flag if set
      installEnv.NODE_ENV = 'production'; // Keep NODE_ENV as production
      
      execSync('npm install', { 
        stdio: 'inherit', 
        cwd: backendDir,
        env: installEnv
      });
      console.log('✅ DevDependencies installed');
    } catch (error) {
      console.error('❌ Failed to install devDependencies:', error.message);
      process.exit(1);
    }
  }
  
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

