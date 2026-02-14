# BugBoard - Issue Tracking System

BugBoard is a complete full-stack application for bug and issue tracking, developed as a software engineering project. It consists of a RESTful backend in Node.js and a cross-platform frontend in Flutter.

## 🏗 Architecture

The project is divided into two main components:

*   **Backend:** Node.js with Express and Sequelize (ORM). It manages APIs, authentication, and the connection with the PostgreSQL database.
*   **Frontend:** Flutter application (Android/iOS/Web/Linux) for user interaction.
*   **Database:** PostgreSQL.
*   **Storage:** Cloudinary for managing file uploads (images/attachments).

## 🚀 Tech Stack

### Backend
*   **Runtime:** Node.js
*   **Framework:** Express.js
*   **Database:** PostgreSQL
*   **ORM:** Sequelize
*   **Authentication:** JWT (JSON Web Tokens)
*   **File Storage:** Cloudinary
*   **Testing:** Jest

### Frontend
*   **Framework:** Flutter
*   **Http Client:** http
*   **State Management:** (Standard/StatefulWidgets)

### DevOps
*   Docker & Docker Compose for containerization and orchestration.

## 🛠 Prerequisites

*   **Docker & Docker Compose** (Recommended for running the complete stack)
*   *Alternatively for local development:*
    *   Node.js (v18+)
    *   PostgreSQL
    *   Flutter SDK (v3.0+)

## 📦 Installation & Running

### Option 1: Using Docker Compose (Recommended)

1.  **Clone the repository:**
    ```bash
    git clone <repo_url>
    cd INGSW
    ```

2.  **Environment Configuration:**
    Ensure you have a `.env` file in the `backend/` folder with the necessary configurations (DB, Cloudinary, JWT).
    *See the [Environment Variables](#-environment-variables) section below.*

3.  **Start the application:**
    ```bash
    docker-compose up --build
    ```
    *   The **Backend** will be available at: `http://localhost:3000`
    *   The **Database** runs on port `5432`.
    *   The **Frontend** (Web version) will be served (check docker logs for the exposed port if configured with Nginx, otherwise run Flutter locally).

### Option 2: Manual Setup

#### Backend
1.  Navigate to the backend folder:
    ```bash
    cd backend
    ```
2.  Install dependencies:
    ```bash
    npm install
    ```
3.  Configure the `.env` file.
4.  Start the server:
    ```bash
    npm start
    # Or for development with hot-reload:
    npm run dev
    ```

#### Frontend
1.  Navigate to the frontend folder:
    ```bash
    cd bugboard_frontend
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the app:
    ```bash
    flutter run
    ```

## 🔑 Environment Variables

Create a `.env` file in the `backend/` directory with the following variables:

```env
# Database Configuration
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=IngSW
DB_PORT=5432
DB_DIALECT=postgres

# Security
JWT_SECRET=your_super_secret_key
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123

# Cloudinary (Image Uploads)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

## ✨ Features

*   **User Authentication:** Registration and Login (JWT).
*   **Role Management:** Standard users and Administrators.
*   **Issue Management:** Create, read, update, and delete reporting/bugs.
*   **Filtering:** Filter issues by tags or status.
*   **Comments:** Add comments to issues.
*   **Attachments:** Upload images using Cloudinary.

## 📂 Project Structure

```
INGSW/
├── backend/                # Node.js/Express Server
│   ├── config/             # DB and Cloudinary Config
│   ├── controllers/        # Request logic (Auth, Issue, Comment)
│   ├── models/             # Sequelize Models
│   ├── routes/             # API Routes
│   └── ...
├── bugboard_frontend/      # Flutter App
│   ├── lib/
│   │   ├── models/
│   │   ├── screens/
│   │   └── services/
│   └── ...
├── docs/                   # Documentation and Diagrams
└── docker-compose.yml      # Docker Orchestration
```

## 🧪 Testing

*   **Backend Tests:**
    ```bash
    cd backend
    npm test
    ```
