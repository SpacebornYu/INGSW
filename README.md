# BugBoard - Sistema di Tracciamento Segnalazioni

BugBoard è un'applicazione full-stack completa per la gestione e il tracciamento di bug e segnalazioni, sviluppata come progetto di ingegneria del software. Consiste in un backend RESTful in Node.js e un frontend multipiattaforma in Flutter.

## 🏗 Architettura

Il progetto è diviso in due componenti principali:

*   **Backend:** Node.js con Express e Sequelize (ORM). Gestisce le API, l'autenticazione e la connessione con il database PostgreSQL.
*   **Frontend:** Applicazione Flutter (Android/iOS/Web/Linux) per l'interazione con l'utente.
*   **Database:** PostgreSQL.
*   **Storage:** Cloudinary per la gestione dei caricamenti di file (immagini/allegati).

## 🚀 Stack Tecnologico

### Backend
*   **Runtime:** Node.js
*   **Framework:** Express.js
*   **Database:** PostgreSQL
*   **ORM:** Sequelize
*   **Autenticazione:** JWT (JSON Web Tokens)
*   **Archiviazione File:** Cloudinary
*   **Testing:** Jest

### Frontend
*   **Framework:** Flutter
*   **Client Http:** http
*   **Gestione Stato:** (Standard/StatefulWidgets)

### DevOps
*   Docker & Docker Compose per la containerizzazione e l'orchestrazione.

## 🛠 Prerequisiti

*   **Docker & Docker Compose** (Consigliato per eseguire l'intero stack)
*   *Alternativamente per lo sviluppo locale:*
    *   Node.js (v18+)
    *   PostgreSQL
    *   Flutter SDK (v3.0+)

## 📦 Installazione e Avvio

### Opzione 1: Utilizzando Docker Compose (Consigliato)

1.  **Clona la repository:**
    ```bash
    git clone <url_repo>
    cd INGSW
    ```

2.  **Configurazione Ambiente:**
    Assicurati di avere un file `.env` nella cartella `backend/` con le configurazioni necessarie (DB, Cloudinary, JWT).
    *Vedi la sezione [Variabili d'Ambiente](#-variabili-dambiente) qui sotto.*

3.  **Avvia l'applicazione:**
    ```bash
    docker-compose up --build
    ```
    *   Il **Backend** sarà disponibile su: `http://localhost:3000`
    *   Il **Database** è in esecuzione sulla porta `5432`.
    *   Il **Frontend** (versione Web) verrà servito (controlla i log di docker per la porta esposta se configurato con Nginx, altrimenti esegui Flutter localmente).

### Opzione 2: Configurazione Manuale

#### Backend
1.  Naviga nella cartella backend:
    ```bash
    cd backend
    ```
2.  Installa le dipendenze:
    ```bash
    npm install
    ```
3.  Configura il file `.env`.
4.  Avvia il server:
    ```bash
    npm start
    # Oppure per lo sviluppo con hot-reload:
    npm run dev
    ```

#### Frontend
1.  Naviga nella cartella frontend:
    ```bash
    cd bugboard_frontend
    ```
2.  Installa le dipendenze:
    ```bash
    flutter pub get
    ```
3.  Esegui l'app:
    ```bash
    flutter run
    ```

## 🔑 Variabili d'Ambiente

Crea un file `.env` nella directory `backend/` con le seguenti variabili:

```env
# Configurazione Database
DB_HOST=localhost
DB_USER=postgres
DB_PASSWORD=tua_password
DB_NAME=IngSW
DB_PORT=5432
DB_DIALECT=postgres

# Sicurezza
JWT_SECRET=tua_chiave_segreta
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=admin123

# Cloudinary (Caricamento Immagini)
CLOUDINARY_CLOUD_NAME=tuo_cloud_name
CLOUDINARY_API_KEY=tua_api_key
CLOUDINARY_API_SECRET=tua_api_secret
```

## ✨ Funzionalità

*   **Autenticazione Utente:** Registrazione e Login (JWT).
*   **Gestione Ruoli:** Utenti standard e Amministratori.
*   **Gestione Segnalazioni:** Creazione, lettura, aggiornamento e cancellazione di segnalazioni/bug.
*   **Filtri:** Filtra le segnalazioni per tag o stato.
*   **Commenti:** Aggiungi commenti alle segnalazioni.
*   **Allegati:** Carica immagini utilizzando Cloudinary.

## 📂 Struttura del Progetto

```
INGSW/
├── backend/                # Server Node.js/Express
│   ├── config/             # Configurazione DB e Cloudinary
│   ├── controllers/        # Logica delle Richieste (Auth, Issue, Comment)
│   ├── models/             # Modelli Sequelize
│   ├── routes/             # Rotte API
│   └── ...
├── bugboard_frontend/      # App Flutter
│   ├── lib/
│   │   ├── models/
│   │   ├── screens/
│   │   └── services/
│   └── ...
├── docs/                   # Documentazione e Diagrammi
└── docker-compose.yml      # Orchestrazione Docker
```

## 🧪 Testing

*   **Test Backend:**
    ```bash
    cd backend
    npm test
    ```
