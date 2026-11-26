/// Enum peran pengguna sesuai PRD Section 4A.
enum UserRole {
  user('user', 'Warga'),
  admin('admin', 'Petugas / Admin');

  const UserRole(this.value, this.label);

  final String value;
  final String label;
}
