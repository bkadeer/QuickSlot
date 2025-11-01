# 📘 QuickSlot Reservation System — Technical Overview

**Version:** 1.0  
**Last Updated:** October 2025  
**Frontend:** Flutter (Dart)  
**Backend:** FastAPI (Python)  
**Platforms:** iOS, Android, Web

## 1. 👁️ Overview

QuickSlot is a cross-platform reservation app designed for seamless and precise booking experiences. Users can book, manage, and receive real-time notifications about their reservations.

**Key Features:**
- 🔐 Biometric authentication (Face ID / Fingerprint)
- 🔓 Smart unlock for web sessions
- 🔔 Real-time push notifications
- 📱 Cross-platform support (iOS, Android, Web)

## 2. 🏗️ System Architecture (High-Level)

     ┌──────────────────────┐
     │    Flutter App       │
     │ (iOS / Android / Web)│
     └──────────┬───────────┘
                │  REST / WebSocket
                ▼
        ┌────────────────────┐
        │     FastAPI API    │
        │  - REST Endpoints  │
        │  - WebSockets      │
        │  - Auth (JWT/OAuth)│
        └────────────────────┘
                   │       
     ┌─────────────┼───────────────┐
     │             │               │
     ▼             ▼               ▼
┌────────┐   ┌──────────┐   ┌─────────────┐
│Postgres│   │  Redis   │   │ Firebase    │
│Database│   │ (Cache & │   │ Cloud Msg.  │
│        │   │ Pub/Sub) │   │ (Push Notif)│
└────────┘   └──────────┘   └─────────────┘
     │
     ▼
┌─────────────┐
│ Celery (BG  │
│ Tasks: email│
│ reminders)  │
└─────────────┘


## 3. ⚙️ Core Components

### 3.1 📱 Frontend (Flutter + Dart)

**Responsibilities:**
- Display real-time slot availability and status
- Handle bookings, cancellations, and payments
- Manage authentication (biometrics, JWT)
- Display in-app and push notifications
- Responsive design for web and mobile

**Tech Stack:**

| Feature          | Library                |
| ---------------- | ---------------------- |
| State Management | Riverpod 3             |
| API Calls        | Dio                    |
| Realtime         | web_socket_channel     |
| Animations       | Rive / Lottie          |
| Local Auth       | local_auth             |
| Secure Storage   | flutter_secure_storage |
| Charts           | fl_chart               |
| Routing          | GoRouter               |


### 3.2 🚀 Backend (FastAPI + Python)

**Responsibilities:**
- Handle REST and WebSocket API endpoints
- Manage booking logic and data transactions
- Authenticate users with JWT + OAuth2
- Send push notifications (via Firebase FCM)
- Generate and validate web unlock codes
- Background tasks (Celery)

**Tech Stack:**

| Module           | Library        |
| ---------------- | -------------- |
| Web Framework    | FastAPI        |
| ORM              | SQLAlchemy 2.0 |
| Database         | PostgreSQL     |
| Cache / Realtime | Redis          |
| Background Tasks | Celery + Redis |
| Auth             | FastAPI Users  |
| Validation       | Pydantic v2    |
| Server           | Uvicorn        |


### 3.3 🗄️ Database (PostgreSQL)
| Table             | Description                    |
| ----------------- | ------------------------------ |
| `users`           | User info, auth credentials    |
| `slots`           | Reservation slots and status   |
| `bookings`        | Booking transactions           |
| `devices`         | Linked mobile devices for auth |
| `unlock_requests` | Temporary codes for web unlock |
| `notifications`   | History of sent notifications  |


### 3.4 ⚡ Cache & Pub/Sub (Redis)

**Used for:**

* Real-time updates between FastAPI instances
* WebSocket event broadcasting
* Temporary storage of unlock codes
* Rate limiting

### 3.5 🔔 Push Notifications (Firebase Cloud Messaging)

#### Used to

* Notify users when bookings are confirmed
* Send reminders ("Your booking starts in 15 minutes")
* Trigger unlock prompts for web sessions

### 3.6 ⏱️ Background Jobs (Celery)

#### Used for

* Sending delayed notifications or emails
* Cleaning expired bookings
* Running reports
- Running reports

---

## 4. 🔒 Authentication & Security

### 4.1 📱 Mobile App

- **Biometric login:** via `local_auth`
- **JWT storage:** securely in `flutter_secure_storage`
- **OAuth2 support:** Apple / Google login
- **Session refresh:** via refresh tokens and short-lived JWTs

### 4.2 🌐 Web App

- **Primary login:** email + password + 2FA (optional)

**Smart unlock flow:**
1. User requests unlock → server generates one-time code
2. Mobile app receives push notification
3. User authenticates (biometrics) and approves
4. Server validates and opens the web session

### 4.3 🛡️ Backend Security

- **HTTPS + CORS:** for Flutter Web
- **JWT middleware:** for protected routes
- **Rate limiting:** Redis via `slowapi`
- **Secrets management:** encrypted tokens via environment variables

---

## 5. 🔔 Notifications System
| Type                  | Trigger                      | Delivered By  | Behavior                               |
| --------------------- | ---------------------------- | ------------- | -------------------------------------- |
| **In-app (live)**     | Booking created/updated      | WebSocket     | Instant update                         |
| **Push notification** | Booking confirmed, reminders | FCM           | App receives system-level notification |
