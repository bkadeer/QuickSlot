#!/bin/bash

echo "======================================"
echo "QuickSlot Backend - Development Server"
echo "======================================"
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install -r requirements.txt

# Create .env if it doesn't exist
if [ ! -f ".env" ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "⚠️  Please update .env with your database credentials"
fi

echo ""
echo "🚀 Starting server..."
echo "📖 Swagger UI: http://localhost:8000/docs"
echo "📖 ReDoc: http://localhost:8000/redoc"
echo ""

# Run the server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
