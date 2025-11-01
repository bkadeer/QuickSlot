# QuickSlot Backend API

FastAPI backend with JWT authentication, PostgreSQL database, and automatic Swagger documentation.

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

Or use a virtual environment:
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Setup Database

**Option A: Use SQLite (for quick testing)**
Update `app/config.py`:
```python
DATABASE_URL: str = "sqlite:///./quickslot.db"
```

**Option B: Use PostgreSQL (recommended)**

Install PostgreSQL, then create database:
```bash
psql -U postgres
CREATE DATABASE quickslot_db;
CREATE USER quickslot WITH PASSWORD 'quickslot123';
GRANT ALL PRIVILEGES ON DATABASE quickslot_db TO quickslot;
\q
```

Update `.env` file (copy from `.env.example`):
```bash
cp .env.example .env
# Edit .env with your database credentials
```

### 3. Create Admin User

```bash
python create_admin.py
```

Default credentials:
- **Email**: `admin@quickslot.com`
- **Password**: `admin123`

### 4. Run the Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 5. Access Swagger Documentation

Open your browser and navigate to:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **API Root**: http://localhost:8000

## 📚 API Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register new user |
| POST | `/api/v1/auth/login` | Login with email/password |
| POST | `/api/v1/auth/refresh` | Refresh access token |
| GET | `/api/v1/auth/me` | Get current user |
| POST | `/api/v1/auth/logout` | Logout user |
| POST | `/api/v1/auth/password-reset/request` | Request password reset |

## 🧪 Testing with Swagger

1. Go to http://localhost:8000/docs
2. Click on `/api/v1/auth/login`
3. Click "Try it out"
4. Enter credentials:
   ```json
   {
     "email": "admin@quickslot.com",
     "password": "admin123"
   }
   ```
5. Click "Execute"
6. Copy the `access_token` from the response
7. Click "Authorize" button at the top
8. Enter: `Bearer <your-access-token>`
9. Now you can test authenticated endpoints

## 🔐 Environment Variables

Create a `.env` file from `.env.example`:

```env
DATABASE_URL=postgresql://quickslot:quickslot123@localhost:5432/quickslot_db
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7
```

## 📦 Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application
│   ├── config.py            # Settings & configuration
│   ├── database.py          # Database connection
│   ├── auth/                # Authentication utilities
│   │   └── utils.py         # JWT & password hashing
│   ├── models/              # SQLAlchemy models
│   │   └── user.py          # User model
│   ├── schemas/             # Pydantic schemas
│   │   └── user.py          # User schemas
│   └── routers/             # API routes
│       └── auth.py          # Auth endpoints
├── create_admin.py          # Admin user creation script
├── requirements.txt         # Python dependencies
└── .env.example             # Environment template
```

## 🛠️ Development

### Run with auto-reload
```bash
uvicorn app.main:app --reload
```

### Run on different port
```bash
uvicorn app.main:app --reload --port 8080
```

### Check API health
```bash
curl http://localhost:8000/health
```

## 🔗 Connect Frontend

The Flutter frontend is already configured to connect to:
```
http://localhost:8000/api/v1
```

Just run both servers:
1. Backend: `uvicorn app.main:app --reload`
2. Frontend: `cd ../frontend && flutter run`

## 📝 Creating Additional Users

### Via API (Register endpoint)
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "name": "John Doe"
  }'
```

### Via Python Script
```python
python create_admin.py
```

## 🐛 Troubleshooting

### Database Connection Error
- Check PostgreSQL is running: `pg_isready`
- Verify database exists: `psql -l`
- Check credentials in `.env`

### Import Errors
- Ensure virtual environment is activated
- Run `pip install -r requirements.txt`

### Port Already in Use
- Change port: `uvicorn app.main:app --reload --port 8001`
- Or kill existing process

## 📄 License

MIT License - see LICENSE file for details
