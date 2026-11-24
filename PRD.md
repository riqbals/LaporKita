# PRD: LaporKita – Public Complaint Management System

> **Context for AI Agents:** Dokumen ini adalah *Single Source of Truth* untuk pengembangan aplikasi mobile **LaporKita** serta acuan pembuatan artefak sistem (ERD, DFD, Use Case, Firestore Rules, dan kode Flutter). Ikuti batasan *MVP Scope*, nama *collection/field*, dan *enum* di bawah ini secara ketat tanpa menambahkan fitur di luar ruang lingkup.

## 1. Overview & Tech Stack

* **Tujuan:** Aplikasi mobile pelaporan fasilitas umum/pelayanan publik (jalan rusak, lampu jalan, drainase, sampah, dll.) dengan pemantauan status *real-time* antara Masyarakat dan Admin.

* **Framework:** Flutter (Dart), target minimal Android 6.0 (API 23).

* **Backend:** Firebase Authentication (Email/Password), Cloud Firestore, Firebase Storage.

* **Konteks Regulasi (Referensi Dokumen):** UU No. 25/2009 & Perpres No. 76/2013 tentang Pelayanan Publik.

## 2. Roles & Permissions (RBAC Matrix)

*Acuan untuk Use Case, DFD, dan Firestore Security Rules.*

| Entitas / Aksi | `user` (Masyarakat) | `admin` (Petugas) | Aturan Validasi | 
| ----- | ----- | ----- | ----- | 
| **Auth** (Register / Login / Logout) | Ya | Login & Logout | Register otomatis set `role: "user"`. | 
| **Profile** (Read / Update `name`, `phone`) | Milik sendiri | Milik sendiri | Tidak boleh mengubah `role` atau `uid`. | 
| **Complaint – Create** | Ya | Tidak | Status awal wajib `"Menunggu"`, `adminResponse: ""`. | 
| **Complaint – Read** | Milik sendiri (`userId == uid`) | Semua dokumen | Real-time menggunakan Firestore `Stream`. | 
| **Complaint – Update** (`status`, `adminResponse`) | **Dilarang** | Ya | Wajib isi `adminResponse` jika status `"Selesai"` / `"Ditolak"`. | 
| **Complaint – Delete** | Milik sendiri **hanya jika `status == "Menunggu"`** | Tidak | Hapus dokumen Firestore + file foto di Storage. | 

## 3. MVP Scope & Strict Constraints

### In-Scope (Fitur Wajib)

1. **Init & Auth:** Splash Screen (cek sesi `FirebaseAuth`), Onboarding (1x), Login, Register, auto-redirect berdasarkan `role`.

2. **User – Beranda & Buat Aduan:** Daftar aduan pribadi (*real-time*), Form Buat Aduan (Judul, Kategori, Deskripsi, Alamat teks, Foto dari kamera/galeri).

3. **User – Detail & Profil:** Detail aduan + tanggapan admin, tombol **Batalkan/Hapus** (khusus `Menunggu`), Lihat/Edit Profil (`name`, `phone`), Halaman FAQ statis, Logout.

4. **Admin – Dashboard & Tanggapan:** Ringkasan jumlah aduan per status, filter daftar aduan berdasarkan status, ubah status + tulis tanggapan resmi.

### Out-of-Scope (JANGAN DIIMPLEMENTASIKAN)

* ❌ Verifikasi e-KTP / API Dukcapil

* ❌ Live Chat 2 arah

* ❌ Google Maps API berbayar (gunakan input alamat teks)

* ❌ Ekspor PDF/Excel & *Offline-first caching* kompleks

* ❌ Push Notification FCM (opsional/di luar MVP utama)

## 4. Data Schema (Acuan ERD & Models)

### A. Firestore Collection: `users`

* **Document ID:** `uid` (dari Firebase Auth)

* **Relasi (ERD):** `users (1)` ─── `<membuat>` ─── `(N) complaints` via `complaints.userId`

| Field | Type | Constraints / Values | 
| ----- | ----- | ----- | 
| `uid` | `String` | Required, PK (Firebase Auth UID) | 
| `name` | `String` | Required | 
| `email` | `String` | Required, valid email | 
| `phone` | `String` | Optional, default `""` | 
| `role` | `String` | Enum: `"user"` | `"admin"` | 
| `createdAt` | `Timestamp` | Required (`FieldValue.serverTimestamp()`) | 

### B. Firestore Collection: `complaints`

* **Document ID:** Auto-generated (`complaintId`)

| Field | Type | Constraints / Values | 
| ----- | ----- | ----- | 
| `complaintId` | `String` | Required, PK | 
| `userId` | `String` | Required, FK -> `users.uid` | 
| `userName` | `String` | Required (denormalisasi dari `users.name`) | 
| `title` | `String` | Required, max 80 chars | 
| `category` | `String` | Enum: `"Jalan & Jembatan"` | `"Lampu Jalan"` | `"Drainase"` | `"Sampah"` | `"Lainnya"` | 
| `description` | `String` | Required | 
| `locationAddress` | `String` | Required (teks alamat/patokan) | 
| `imageUrl` | `String` | Required (download URL dari Firebase Storage) | 
| `status` | `String` | Enum: `"Menunggu"` | `"Diproses"` | `"Selesai"` | `"Ditolak"` | 
| `adminResponse` | `String` | Default `""`, wajib diisi saat status `"Selesai"` / `"Ditolak"` | 
| `createdAt` | `Timestamp` | Required | 
| `updatedAt` | `Timestamp` | Required (diperbarui tiap Admin mengubah status) | 

### C. Firebase Storage Convention

* **Path:** `complaint_images/{complaintId}.jpg`

* **Aturan Media:** Kompresi di sisi klien Flutter sebelum *upload* (kualitas `70–80%`, max resolusi `1080p`).

## 5. Lifecycle & Data Flow (Acuan DFD & State Machine)

### Complaint Status State Machine

```
[User Create] ──► Menunggu ──(User Cancel)──► [Deleted]
                     │
                     ├──(Admin Reject + Response)──► Ditolak (Final)
                     │
                     └──(Admin Verify)──► Diproses ──(Admin Finish + Response)──► Selesai (Final)

```

### Core Data Flows (DFD Level 1)

1. **P1 – Autentikasi:** `User/Admin` → kredensial → Firebase Auth & `users` → sesi + `role`.

2. **P2 – Pengajuan Aduan:** `User` → form + foto terkompresi → Storage (`imageUrl`) + Firestore (`complaints`).

3. **P3 – Pemantauan & Pembatalan:** `User` ↔ *real-time stream* `complaints` (filter `userId`); hapus jika `Menunggu`.

4. **P4 – Penanganan Aduan:** `Admin` → baca semua `complaints` → update `status`, `adminResponse`, `updatedAt`.

5. **P5 – Manajemen Profil:** `User/Admin` ↔ baca/update `name`, `phone` pada `users`.

## 6. Project Structure & Team Modules (Git Workflow)

### Konvensi Folder (`lib/`)

```
lib/
├── core/          # constants (enums, colors, routes), theme, utils (image compressor)
├── models/        # user_model.dart, complaint_model.dart (SHARED - lock di main)
├── services/      # auth_service.dart, complaint_service.dart, storage_service.dart
├── widgets/       # reusable UI (complaint_card, status_badge, custom_input)
└── screens/
    ├── auth/      # splash, onboarding, login, register
    ├── user/      # home_user, create_complaint, detail_complaint
    ├── admin/     # dashboard_admin, detail_admin
    └── profile/   # profile_screen, edit_profile, faq_screen

```