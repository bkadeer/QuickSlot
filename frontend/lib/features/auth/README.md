# Authentication Module

## Overview
Complete authentication system with clean architecture, implementing JWT-based authentication, biometric login, and secure token storage.

## Architecture

### Clean Architecture Layers

```
features/auth/
├── domain/           # Business logic & abstractions
│   ├── entities/     # Core business entities
│   │   └── user.dart
│   └── repositories/ # Repository interfaces
│       └── auth_repository.dart
├── data/             # Data layer implementation
│   ├── models/       # Data models (extend entities)
│   │   └── user_model.dart
│   ├── datasources/  # API & local data sources
│   │   ├── auth_remote_data_source.dart
│   │   └── auth_local_data_source.dart
│   └── repositories/ # Repository implementations
│       └── auth_repository_impl.dart
└── presentation/     # UI layer
    ├── pages/        # Screens
    ├── widgets/      # Reusable widgets
    └── providers/    # Riverpod state management
        └── auth_providers.dart
```

## Features

### ✅ Implemented
- **Email/Password Login** - Backend JWT authentication
- **User Registration** - Create new accounts
- **Biometric Authentication** - Face ID / Fingerprint login
- **Secure Token Storage** - Encrypted token storage using flutter_secure_storage
- **Auto Token Refresh** - Automatic token refresh on expiry
- **Password Reset Request** - Request password reset emails
- **Session Management** - Check login status
- **Logout** - Clear all auth data

### Core Services

#### 1. API Client (`/core/network/api_client.dart`)
- Dio-based HTTP client with interceptors
- Auto-adds JWT tokens to requests
- Auto-refreshes expired tokens
- Handles authentication errors

```dart
final apiClient = ref.watch(apiClientProvider);
```

#### 2. Secure Storage Service (`/core/storage/secure_storage_service.dart`)
- Encrypted storage for sensitive data
- Stores: access tokens, refresh tokens, user data
- Biometric settings persistence

```dart
final storage = ref.watch(secureStorageServiceProvider);
await storage.saveAccessToken(token);
```

## Usage

### 1. Login with Email & Password

```dart
final authNotifier = ref.read(authStateProvider.notifier);

try {
  await authNotifier.login(
    email: 'user@example.com',
    password: 'password123',
  );
  // Navigate to home
} catch (e) {
  // Show error message
}
```

### 2. Register New User

```dart
try {
  await authNotifier.register(
    email: 'user@example.com',
    password: 'password123',
    name: 'John Doe',
    phoneNumber: '+1234567890',
  );
} catch (e) {
  // Handle error
}
```

### 3. Biometric Login

```dart
try {
  await authNotifier.loginWithBiometrics();
  // User authenticated
} catch (e) {
  // Biometric auth failed
}
```

### 4. Enable Biometric Auth

```dart
await authNotifier.enableBiometricAuth();
```

### 5. Logout

```dart
await authNotifier.logout();
```

### 6. Check Auth Status

```dart
// Watch authentication state
ref.watch(isAuthenticatedProvider); // bool

// Get current user
ref.watch(currentUserProvider); // User?

// Check loading state
ref.watch(authLoadingProvider); // bool
```

## Backend API Contract

### Expected Endpoints

#### POST `/api/v1/auth/login`
**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200 OK):**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "John Doe",
    "phone_number": "+1234567890",
    "profile_image_url": "https://...",
    "created_at": "2024-01-01T00:00:00Z",
    "last_login_at": "2024-01-15T12:00:00Z"
  },
  "access_token": "eyJ...",
  "refresh_token": "eyJ..."
}
```

#### POST `/api/v1/auth/register`
**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe",
  "phone_number": "+1234567890"
}
```

**Response (201 Created):**
```json
{
  "user": { /* same as login */ },
  "access_token": "eyJ...",
  "refresh_token": "eyJ..."
}
```

#### GET `/api/v1/auth/me`
**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "name": "John Doe",
  /* ...other user fields */
}
```

#### POST `/api/v1/auth/refresh`
**Request:**
```json
{
  "refresh_token": "eyJ..."
}
```

**Response (200 OK):**
```json
{
  "access_token": "new_access_token",
  "refresh_token": "new_refresh_token"  // optional
}
```

#### POST `/api/v1/auth/logout`
**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "message": "Logged out successfully"
}
```

#### POST `/api/v1/auth/password-reset/request`
**Request:**
```json
{
  "email": "user@example.com"
}
```

**Response (200 OK):**
```json
{
  "message": "Password reset email sent"
}
```

## Configuration

### Set API Base URL

Create a `.env` file or set during build:

```bash
flutter run --dart-define=API_BASE_URL=https://api.quickslot.com/api/v1
```

Default: `http://localhost:8000/api/v1`

### Environment Variables

```env
API_BASE_URL=https://api.quickslot.com/api/v1
```

## Error Handling

All authentication methods throw exceptions on failure:

```dart
try {
  await authNotifier.login(email: email, password: password);
} on AuthenticationException catch (e) {
  // Auth-specific errors (wrong password, etc.)
  print('Auth failed: ${e.message}');
} on NetworkException catch (e) {
  // No internet connection
  print('Network error: ${e.message}');
} on ServerException catch (e) {
  // Server errors (500, etc.)
  print('Server error: ${e.message}');
} catch (e) {
  // Other errors
  print('Unknown error: $e');
}
```

## State Management

### Auth State Structure

```dart
class AuthState {
  final User? user;           // Current user
  final bool isLoading;       // Loading indicator
  final String? error;        // Error message
  final bool isAuthenticated; // Auth status
}
```

### Available Providers

```dart
// Main state provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>;

// Helper providers
final isAuthenticatedProvider = Provider<bool>;
final currentUserProvider = Provider<User?>;
final authLoadingProvider = Provider<bool>;
final authErrorProvider = Provider<String?>;

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>;
```

## Security Features

1. **Encrypted Storage** - All tokens stored with platform encryption
2. **Auto Token Refresh** - Seamless token refresh without user intervention
3. **Biometric Authentication** - Secure device-level authentication
4. **Secure HTTP** - All API calls use HTTPS
5. **Token Expiry Handling** - Automatic cleanup on token expiry

## Testing

The architecture supports easy testing:

```dart
// Mock the repository
final mockAuthRepository = MockAuthRepository();

// Override provider in tests
container.overrideWith(() => mockAuthRepository);
```

## Next Steps

1. **Implement Home Route** - Add navigation after successful login
2. **Add Social Login** - Google/Apple sign-in
3. **Profile Management** - Update user profile
4. **2FA Support** - Two-factor authentication
5. **Password Change** - Allow users to change password
6. **Remember Me** - Optional persistent sessions

## Support

For issues or questions, refer to:
- Architecture docs: `/ARCHITECTURE.md`
- API documentation: Backend repo
- Flutter docs: https://flutter.dev/docs
