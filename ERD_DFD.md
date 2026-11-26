
# ERD & DFD - LaporKita

Dokumentasi perancangan database dan aliran data
Sistem Informasi Manajemen Pelayanan Pengaduan Masyarakat.

---

## 1. Entity Relationship Diagram (ERD)

ERD LaporKita terdiri dari dua entitas utama,
yaitu Users dan Complaints.

### 1.1 Entitas Users

| Field | Type | Key | Description |
|---|---|---|---|
| uid | String | PK | Firebase Authentication UID |
| name | String | - | Nama pengguna |
| email | String | - | Email pengguna |
| phone | String | - | Nomor telepon |
| role | String | - | user atau admin |
| createdAt | Timestamp | - | Waktu akun dibuat |

### 1.2 Entitas Complaints

| Field | Type | Key | Description |
|---|---|---|---|
| complaintId | String | PK | ID pengaduan |
| userId | String | FK | Mengacu ke users.uid |
| userName | String | - | Nama pembuat pengaduan |
| title | String | - | Judul pengaduan |
| category | String | - | Kategori pengaduan |
| description | String | - | Deskripsi pengaduan |
| locationAddress | String | - | Alamat atau patokan |
| imageUrl | String | - | URL foto pengaduan |
| status | String | - | Status pengaduan |
| adminResponse | String | - | Tanggapan admin |
| createdAt | Timestamp | - | Waktu dibuat |
| updatedAt | Timestamp | - | Waktu diperbarui |

### 1.3 Relasi ERD

```mermaid
erDiagram
    USERS ||--o{ COMPLAINTS : membuat

    USERS {
        string uid PK
        string name
        string email
        string phone
        string role
        timestamp createdAt
    }

    COMPLAINTS {
        string complaintId PK
        string userId FK
        string userName
        string title
        string category
        string description
        string locationAddress
        string imageUrl
        string status
        string adminResponse
        timestamp createdAt
        timestamp updatedAt
    }
```

---

## 2. Data Flow Diagram (DFD)

### 2.1 DFD Level 0 (Diagram Konteks)

```mermaid
flowchart LR
    U[User / Masyarakat]
    A[Admin / Petugas]
    S((Sistem LaporKita))

    U -->|Registrasi, login, data pengaduan, pembatalan, profil| S
    S -->|Informasi akun, status, detail dan tanggapan| U

    A -->|Login, perubahan status, tanggapan, profil| S
    S -->|Data pengaduan, dashboard, informasi pengguna| A
```

### 2.2 DFD Level 1

```mermaid
flowchart TB
    U[User / Masyarakat]
    A[Admin / Petugas]

    P1((P1 Autentikasi))
    P2((P2 Pengajuan Aduan))
    P3((P3 Pemantauan dan Pembatalan))
    P4((P4 Penanganan Aduan))
    P5((P5 Manajemen Profil))

    D1[(D1 Users)]
    D2[(D2 Complaints)]
    D3[(D3 Cloudinary)]
    FA[(Firebase Authentication)]

    U -->|Email, password, registrasi| P1
    A -->|Email, password| P1
    P1 <-->|Data akun| FA
    P1 <-->|Profil dan role| D1
    P1 -->|Hasil autentikasi| U
    P1 -->|Hasil autentikasi| A

    U -->|Data pengaduan dan foto| P2
    P2 -->|Simpan foto| D3
    P2 -->|Data pengaduan dan imageUrl| D2
    D1 -->|Informasi pengguna| P2
    P2 -->|Konfirmasi pengajuan| U

    U -->|Permintaan lihat atau batalkan| P3
    P3 <-->|Baca atau perbarui pengaduan| D2
    P3 -->|Daftar, detail dan status| U

    A -->|Status baru dan tanggapan| P4
    D2 -->|Data pengaduan| P4
    P4 -->|Simpan status dan tanggapan| D2
    P4 -->|Konfirmasi perubahan| A

    U -->|Perubahan profil| P5
    A -->|Perubahan profil| P5
    P5 <-->|Baca dan perbarui profil| D1
    P5 -->|Profil terbaru| U
    P5 -->|Profil terbaru| A
```

---

## 3. Data Store

| Kode | Data Store | Keterangan |
|---|---|---|
| D1 | Users | Data akun pengguna dan admin |
| D2 | Complaints | Data pengaduan |
| D3 | Cloudinary | Penyimpanan foto pengaduan |
| FA | Firebase Authentication | Autentikasi akun |

## 4. Relasi dan Aturan Data

- Satu User dapat membuat banyak pengaduan.
- Setiap pengaduan dimiliki oleh satu User.
- User hanya dapat melihat pengaduan miliknya.
- Admin dapat melihat seluruh pengaduan.
- User hanya dapat membatalkan pengaduan berstatus Menunggu.
- Admin dapat mengubah status dan memberikan tanggapan resmi.
