# 🚀 Team Task Manager (Full-Stack)

A full-stack web application that allows teams to **create projects, assign tasks, and track progress** with **role-based access control (Admin / Member)**.
---
## 🌐 Live Demo
👉 https://task-manager-production-a94e.up.railway.app
---
## 📌 Features

### 🔐 Authentication

* User Signup & Login using Firebase Authentication
* Secure user management

### 👥 Role-Based Access

* Admin Dashboard
* Member Dashboard
* Role stored and managed via Firestore

### 📁 Project Management

* Create projects
* View all projects
* Assign members to projects

### ✅ Task Management

* Create tasks
* Assign tasks to users
* Track task status (Pending / Completed)
* Real-time updates using Firestore

### 📊 Dashboard

* View all tasks
* Status tracking
* Overdue task detection (if implemented)

---

## 🛠️ Tech Stack

### Frontend

* Flutter (Web)
* Dart

### Backend / Database

* Firebase Authentication
* Cloud Firestore

### Server (for deployment)

* Node.js (Express)

### Deployment

* Railway (Backend + Hosting)

---

## 🏗️ Project Structure

```
task_manager/
│
├── lib/                 # Flutter UI & logic
├── build/web/           # Production build (Flutter Web)
├── server.js            # Node server (Express)
├── package.json         # Node dependencies
├── pubspec.yaml         # Flutter dependencies
└── README.md
```

---

## ⚙️ Setup Instructions

### 1️⃣ Clone the repository

```
git clone https://github.com/keshavgoel892/task-manager.git
cd task-manager
```

---

### 2️⃣ Install Flutter dependencies

```
flutter pub get
```

---

### 3️⃣ Run locally (Flutter)

```
flutter run -d chrome
```

---

### 4️⃣ Build for production

```
flutter build web
```

---

### 5️⃣ Run Node server

```
npm install
npm start
```

---

## 🔐 Firebase Setup

* Create Firebase project
* Enable Authentication (Email/Password)
* Enable Firestore Database
* Add Firebase config using `firebase_options.dart`

---

## 🚀 Deployment

This project is deployed using Railway:

1. Push code to GitHub
2. Connect repo to Railway
3. Generate domain
4. Deploy Node server

---

## 📷 Demo Video

📌 (Add your 2–5 min demo video link here)

---

## 🧠 Key Concepts Implemented

* Role-Based Access Control (RBAC)
* REST-like architecture using Firebase
* Real-time database (Firestore)
* Full-stack deployment
* Flutter Web production build

---

## 👨‍💻 Author

**Keshav Goel**
📧 [keshavgoel892@gmail.com](mailto:keshavgoel892@gmail.com)
🎓 B.Tech CSE (Final Year)

---

## ⭐ Acknowledgements

* Flutter Team
* Firebase
* Railway

---

## 📌 Note

This project was built as part of a **full-stack assignment** demonstrating real-world application development with authentication, role-based access, and deployment.

---
