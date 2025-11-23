#!/usr/bin/env node

/**
 * Script to verify Zego environment variables are configured correctly
 * Run: node check-zego-env.js
 */

require('dotenv').config();

const zegoAppID = process.env.ZEGO_APP_ID;
const zegoServerSecret = process.env.ZEGO_SERVER_SECRET;

console.log('\n🔍 Checking Zego Environment Variables...\n');

if (!zegoAppID) {
  console.error('❌ ZEGO_APP_ID is NOT SET');
} else {
  const appID = parseInt(zegoAppID, 10);
  if (isNaN(appID) || appID === 0) {
    console.error(`❌ ZEGO_APP_ID is set but invalid: "${zegoAppID}"`);
    console.error('   Expected: A numeric value (e.g., 1234567890)');
  } else {
    console.log(`✅ ZEGO_APP_ID is set: ${appID}`);
  }
}

if (!zegoServerSecret) {
  console.error('❌ ZEGO_SERVER_SECRET is NOT SET');
} else {
  if (zegoServerSecret.length < 10) {
    console.error(`❌ ZEGO_SERVER_SECRET is set but seems too short: ${zegoServerSecret.length} characters`);
    console.error('   Expected: A long string (usually 32+ characters)');
  } else {
    console.log(`✅ ZEGO_SERVER_SECRET is set: ${zegoServerSecret.substring(0, 10)}... (${zegoServerSecret.length} chars)`);
  }
}

if (zegoAppID && zegoServerSecret) {
  const appID = parseInt(zegoAppID, 10);
  if (!isNaN(appID) && appID !== 0 && zegoServerSecret.length >= 10) {
    console.log('\n✅ All Zego credentials are configured correctly!');
    console.log('   You can now use the voice call feature.\n');
  } else {
    console.log('\n⚠️  Some credentials are invalid. Please check your .env file.\n');
  }
} else {
  console.log('\n⚠️  Missing credentials. Please add them to your .env file:\n');
  console.log('   ZEGO_APP_ID=your_app_id_here');
  console.log('   ZEGO_SERVER_SECRET=your_server_secret_here\n');
  console.log('   Example .env format:');
  console.log('   ZEGO_APP_ID=1234567890');
  console.log('   ZEGO_SERVER_SECRET=abcdef1234567890abcdef1234567890\n');
}

