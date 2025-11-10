#!/bin/bash
echo "🔍 Finding processes on port 5000..."
PIDS=$(lsof -ti:5000)
if [ -z "$PIDS" ]; then
  echo "✅ No processes found on port 5000"
else
  echo "🛑 Killing processes: $PIDS"
  kill -9 $PIDS
  sleep 1
  if lsof -ti:5000 > /dev/null 2>&1; then
    echo "⚠️  Some processes couldn't be killed"
  else
    echo "✅ Port 5000 is now free"
  fi
fi
