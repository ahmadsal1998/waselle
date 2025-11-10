#!/bin/bash

echo "🚀 Creating Admin User..."
echo ""

# Check if .env exists
if [ ! -f backend/.env ]; then
  echo "❌ Error: backend/.env file not found!"
  echo "Please create .env file with MONGODB_URI"
  exit 1
fi

# Check if MongoDB is accessible
cd backend
node create-admin.js

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Admin user created successfully!"
  echo ""
  echo "Login credentials:"
  echo "📧 Email: admin@example.com"
  echo "🔑 Password: Admin123456"
  echo ""
  echo "⚠️  Remember to change the password after first login!"
else
  echo ""
  echo "❌ Failed to create admin user"
  echo "Check that:"
  echo "1. MongoDB is running"
  echo "2. MONGODB_URI is correct in backend/.env"
  exit 1
fi
