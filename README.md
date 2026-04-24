# 📱 SIPEKA Mobile App

SIPEKA (Sistem Informasi Pengelolaan Kegiatan) adalah aplikasi mobile berbasis Flutter yang terintegrasi dengan backend Laravel untuk membantu pengelolaan data, aktivitas, dan informasi secara efisien dalam satu platform terpusat.

Aplikasi ini dirancang untuk memberikan kemudahan dalam pengelolaan sistem secara digital, dengan fokus pada performa, kemudahan penggunaan, dan skalabilitas.

---

## 🚀 Fitur Utama

* 🔐 Autentikasi pengguna (Login & Register)
* 📊 Manajemen data kegiatan
* 📁 Pengelolaan informasi terstruktur
* 🔄 Integrasi API antara mobile dan backend
* ⚡ Performa cepat dengan Flutter
* 🛠 Backend REST API menggunakan Laravel

---

## 🏗 Arsitektur Project

Project ini menggunakan pendekatan **monorepo**, di mana backend dan frontend berada dalam satu repository:

```
sipeka/
│
├── backend/
│   └── sipeka/        # Laravel (REST API)
│
├── frontend/
│   └── sipeka/        # Flutter (Mobile App)
│
└── README.md
```

---

## 🧰 Tech Stack

### Backend

* Laravel
* MySQL
* REST API

### Frontend

* Flutter
* Dart


## 🔐 Konfigurasi Environment

Pastikan file `.env` pada backend sudah disesuaikan:

* Database
* App URL
* API configuration


## 📄 License

This project is open-source and available for development and learning purposes.
