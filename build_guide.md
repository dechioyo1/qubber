# Qubber Build & Setup Guide

Qubber is a modern, lightweight XMPP client built with **Python 3**, **PySide6 (Qt Quick/QML)**, **Slixmpp**, and **SQLite**.

This guide covers setting up your development environment, installing dependencies, configuring database storage, and running the application.

---

## 1. System Requirements

Ensure you have the following installed on your system:
- **Python 3.10 or higher** (Python 3.12+ recommended)
- **Pip** (Python package installer)
- **Virtualenv** (optional, but highly recommended)

---

## 2. Dependencies

The Python dependencies required by this project are listed in [requirements.txt](file:///home/dechioyo/Projects/Qubber/requirements.txt):

- **PySide6**: Dynamic Qt Quick / QML user interface framework.
- **slixmpp**: Asynchronous XMPP library for messaging, roster management, and connection handling.
- **qasync**: Integration layer combining Python's `asyncio` loop with the Qt event loop.
- **aiohttp**: Asynchronous HTTP client (required for XEP-0363 HTTP File Upload plugin support).

---

## 3. Installation Steps

### Step 1: Clone or Navigate to the Directory
Ensure you are in the project root directory:
```bash
cd /home/dechioyo/Projects/Qubber
```

### Step 2: Set Up a Python Virtual Environment
Creating a virtual environment ensures dependencies do not conflict with system packages:
```bash
# Create a virtual environment named 'venv'
python -m venv venv

# Activate the virtual environment
source venv/bin/activate
```

### Step 3: Install Dependencies
Install all required libraries using pip:
```bash
pip install -r requirements.txt
```

---

## 4. Run the Application

Once dependencies are installed, start the client using the main entry point:
```bash
python main.py
```

### Troubleshooting SASL TLS 1.3 Binding Warn
When running python, you might see the following log statement:
> `SASL: SCRAM-PLUS requires channel binding, but Python ssl only supports tls-unique which is unavailable on TLS 1.3...`

This is standard behavior under Python's SSL wrapper for TLS 1.3 connections. The client automatically falls back to secure non-PLUS authentication (e.g., standard SCRAM-SHA-1 or PLAIN), which is fully supported by all modern XMPP servers.

---

## 5. Storage & Databases

Qubber stores its database locally. Upon startup, it checks and initializes database tables automatically.

- **Linux Database Path**: `~/.local/share/Qubber/Qubber/qubber.db`
- **Database Type**: SQLite 3

To inspect or reset the database locally:
```bash
# View database table structures
sqlite3 ~/.local/share/Qubber/Qubber/qubber.db .tables

# To completely reset the local profile database (resets login credentials and cache)
rm -f ~/.local/share/Qubber/Qubber/qubber.db
```

---

## 6. Project Architecture

The codebase is split into backend logic and a QML graphical presentation layer:

```
Qubber/
├── main.py                # Initializes App Engine, Theme Manager, and QML view loading.
├── backend.py             # XMPP connection client, SQLite management, and message slots.
├── roster_model.py        # Qt Model presenting roster/contact details to the sidebar list.
├── chat_model.py          # Qt Model handling message history.
├── theme_manager.py       # Manages application styling, loaded palettes, and dark mode colors.
├── requirements.txt       # Project python packages list.
└── qml/                   # QML Layouts, components, and delegates.
    ├── main.qml           # Main application shell (window controls, title, and menus).
    ├── ChatView.qml       # Active conversation header and message log.
    ├── ContactDelegate.qml# Contact roster list items rendering.
    ├── MessageDelegate.qml# Message bubbles with dynamic wrapping.
    └── AddContactDialog.qml# Contacts search and inclusion popup.
```
