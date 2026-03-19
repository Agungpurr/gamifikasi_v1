# 🎮 Gamifikasi — Aplikasi Pembelajaran Berbasis Gamifikasi

Aplikasi mobile edukatif berbasis **Flutter** yang menerapkan elemen gamifikasi untuk meningkatkan motivasi belajar siswa. Pengguna dapat belajar Matematika dan Bahasa Indonesia sambil mengumpulkan poin, lencana, dan menjaga streak belajar harian.

---

## 📱 Tampilan Aplikasi

| Beranda                                  | Belajar                           |
| ---------------------------------------- | --------------------------------- |
| Dashboard dengan XP, streak, dan lencana | Pilih mata pelajaran & mulai kuis |

---

## ✨ Fitur Utama

- 🏠 **Beranda (Home)** — Menampilkan profil pengguna, XP bar, streak harian, jumlah lencana, dan level
- 📚 **Belajar** — Pilih mata pelajaran (Matematika, Bahasa Indonesia, dll.) dan kerjakan soal kuis
- 🏆 **Peringkat (Leaderboard)** — Lihat posisi kamu dibanding pengguna lain
- 👤 **Profil** — Informasi akun dan riwayat belajar
- 🎖️ **Lencana (Badges)** — Raih lencana berdasarkan pencapaian belajar
- 🔥 **Streak Harian** — Konsistensi belajar setiap hari dihargai dengan streak
- ⭐ **Sistem Poin & Level** — Setiap soal yang dijawab memberi XP dan poin

---

## 🗂️ Struktur Proyek

```
lib/
├── models/
│   ├── badge_model.dart
│   ├── question_model.dart
│   └── user_model.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── badges/
│   │   └── badges_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── leaderboard/
│   │   └── leaderboard_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   └── quiz/
│       ├── quiz_screen.dart
│       ├── quiz_result_screen.dart
│       └── subject_select_screen.dart
├── services/
├── utils/
├── firebase_options.dart
└── main.dart
```

---

## 🛠️ Teknologi yang Digunakan

| Teknologi                               | Keterangan                   |
| --------------------------------------- | ---------------------------- |
| [Flutter](https://flutter.dev)          | Framework UI cross-platform  |
| [Dart](https://dart.dev)                | Bahasa pemrograman utama     |
| [Firebase](https://firebase.google.com) | Auth, Firestore, dan backend |
| Google Services                         | Integrasi layanan Google     |

---

## 🚀 Cara Menjalankan

### Prasyarat

- Flutter SDK `>= 3.0.0`
- Dart SDK
- Android Studio / VS Code
- Akun Firebase (dengan project yang sudah dikonfigurasi)

### Langkah-langkah

1. **Clone repository ini**

   ```bash
   git clone https://github.com/Agungpurr/gamifikasi_v1.git
   cd gamifikasi_v1
   ```

2. **Install dependensi**

   ```bash
   flutter pub get
   ```

3. **Konfigurasi Firebase**
   - Buat project di [Firebase Console](https://console.firebase.google.com)
   - Download `google-services.json` dan letakkan di `android/app/`
   - Pastikan `lib/firebase_options.dart` sudah dikonfigurasi

4. **Jalankan aplikasi**
   ```bash
   flutter run
   ```

---

## 📦 Dependensi Utama

Lihat `pubspec.yaml` untuk daftar lengkap dependensi yang digunakan.

---

## 🔐 Fitur Autentikasi

- Login dengan email & password
- Registrasi akun baru
- Autentikasi menggunakan Firebase Auth

---

## 📊 Sistem Gamifikasi

| Elemen                     | Deskripsi                               |
| -------------------------- | --------------------------------------- |
| **XP (Experience Points)** | Didapat dari menjawab soal dengan benar |
| **Level**                  | Naik sesuai akumulasi XP                |
| **Poin**                   | Mata uang dalam aplikasi                |
| **Streak**                 | Hari berturut-turut login & belajar     |
| **Lencana**                | Penghargaan atas pencapaian tertentu    |
| **Leaderboard**            | Peringkat antar pengguna                |

---

## 🤝 Kontribusi

Kontribusi sangat terbuka! Silakan buat _issue_ atau _pull request_ jika ingin menambah fitur atau memperbaiki bug.

1. Fork repository ini
2. Buat branch fitur baru: `git checkout -b fitur/nama-fitur`
3. Commit perubahan: `git commit -m 'Tambah fitur: nama-fitur'`
4. Push ke branch: `git push origin fitur/nama-fitur`
5. Buat Pull Request

---

## 📄 Lisensi

Proyek ini menggunakan lisensi [MIT](LICENSE).

---

## 👨‍💻 Developer

**Agung Purr**

- GitHub: [@Agungpurr](https://github.com/Agungpurr)

---

> 💡 _Belajar lebih menyenangkan dengan gamifikasi!_ 🚀
