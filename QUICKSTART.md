# 🚀 QuickSlot - Quick Start Guide

## Current Setup Status
✅ Backend API running on http://localhost:8000  
✅ Frontend authentication integrated  
✅ Database created (SQLite)  

## Step 1: Create Admin User

Open a **NEW terminal** and run:

```bash
cd /Users/admin/projects/QuickSlot/backend
source venv/bin/activate
python create_admin.py
```

Press Enter for defaults:
- **Email**: `admin@quickslot.com`
- **Password**: `admin123`
- **Name**: `Admin`

## Step 2: Run the Flutter App

In another terminal:

```bash
cd /Users/admin/projects/QuickSlot/frontend
flutter run -d chrome  # For web browser
# OR
flutter run -d macos   # For macOS desktop app
```

## Step 3: Test Login

1. The app will open to the login page
2. Enter credentials:
   - **Email**: `admin@quickslot.com`
   - **Password**: `admin123`
3. Click **Sign In**
4. You'll be redirected to the home page showing your user info!

## Alternative: Test with Swagger

1. Go to http://localhost:8000/docs
2. Try **POST /api/v1/auth/login**
3. Click "Try it out"
4. Enter:
   ```json
   {
     "email": "admin@quickslot.com",
     "password": "admin123"
   }
   ```
5. Click "Execute"
6. You'll get back:
   - User data
   - `access_token`
   - `refresh_token`

## Create New Users

### Via Flutter App:
1. Click **Sign Up** on login page
2. Fill in the form
3. Click **Sign Up**

### Via Swagger:
1. Go to http://localhost:8000/docs
2. Try **POST /api/v1/auth/register**
3. Enter user details

## Current Features

✅ **Email/Password Login**  
✅ **User Registration**  
✅ **JWT Token Authentication**  
✅ **Secure Token Storage**  
✅ **Auto Token Refresh**  
✅ **Password Reset Request**  
✅ **Biometric Auth Setup Prompt**  
✅ **Session Management**  
✅ **Logout**  

## Backend API Endpoints

- `POST /api/v1/auth/login` - Login
- `POST /api/v1/auth/register` - Register
- `POST /api/v1/auth/refresh` - Refresh token
- `POST /api/v1/auth/logout` - Logout
- `POST /api/v1/auth/password-reset/request` - Reset password
- `GET /health` - Health check

## Troubleshooting

### Backend not running?
```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend build issues?
```bash
cd frontend
flutter pub get
flutter clean
flutter run
```

### Database issues?
Delete the database and recreate:
```bash
cd backend
rm quickslot.db
python create_admin.py
```

## Next Steps

- [ ] Implement home page features
- [ ] Add booking functionality
- [ ] Integrate real-time notifications
- [ ] Add profile management
- [ ] Implement password change
- [ ] Add 2FA support

---

**🎉 Your authentication system is fully functional!**
