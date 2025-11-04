#!/bin/bash

# QuickSlot Backend - Development Server
# This script runs the backend on 0.0.0.0 so it's accessible from real devices on the local network

echo "🚀 Starting QuickSlot Backend Server..."
echo "📱 Accessible from:"
echo "   - Simulator: http://127.0.0.1:8000"
echo "   - Real Device: http://10.0.0.240:8000"
echo "   - Docs: http://10.0.0.240:8000/docs"
echo ""

# Run uvicorn on 0.0.0.0 to accept connections from any network interface
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
