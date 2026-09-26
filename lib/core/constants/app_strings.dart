abstract final class AppStrings {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const String systemName = 'Sistem Internal YukBersihin';
  static const String portalSubtitle = 'Portal operasional tim YukBersihin';

  // ── Common ─────────────────────────────────────────────────────────────────
  static const String tryAgain = 'Coba Lagi';
  static const String cancel = 'Batal';
  static const String failedLoadData = 'Gagal memuat data';
  static const String lunas = 'Lunas';
  static const String totalFinal = 'Total Akhir';
  static const String downPaymentLabel = 'Uang Muka (DP)';
  static const String remainingBill = 'Sisa Tagihan';
  static const String subtotalLabel = 'Subtotal';
  static const String discountLabel = 'Diskon';
  static const String rpPrefix = 'Rp ';
  static const String otherCategory = 'Lainnya';
  static const String sessionExpired = 'Sesi berakhir. Silakan login kembali.';

  // ── Login ──────────────────────────────────────────────────────────────────
  static const String loginTitle = 'Masuk ke Sistem';
  static const String loginSubtitle =
      'Gunakan akun staff untuk mengakses aplikasi.';
  static const String loginButton = 'Masuk';
  static const String emailLabel = 'Email';
  static const String emailHint = 'Masukkan email';
  static const String emailEmpty = 'Email tidak boleh kosong';
  static const String emailInvalid = 'Format email tidak valid';
  static const String passwordLabel = 'Kata Sandi';
  static const String passwordHint = 'Masukkan kata sandi';
  static const String passwordEmpty = 'Kata sandi tidak boleh kosong';
  static const String passwordMinLength = 'Kata sandi minimal 8 karakter';

  // ── Home ───────────────────────────────────────────────────────────────────
  static const String greeting = 'Halo,';
  static const String defaultStaffName = 'Staff YukBersihin';
  static const String statusUpdated = 'Status berhasil diperbarui';
  static const String finalItemsSent = 'Laporan item akhir berhasil dikirim!';
  static const String menuEditProfile = 'Edit Profil';
  static const String menuChangePassword = 'Ubah Kata Sandi';
  static const String menuHttpInspector = 'HTTP Inspector';
  static const String menuLogout = 'Keluar';
  static const String logoutTitle = 'Keluar Akun';
  static const String logoutConfirm = 'Apakah Anda ingin keluar dari akun ini?';
  static const String jobsOnDate = 'pekerjaan di tanggal ini';
  static const String jobsCompleted = 'selesai';

  // ── Notification ───────────────────────────────────────────────────────────
  static const String notificationsTitle = 'Notifikasi';
  static const String markAllRead = 'Baca Semua';
  static const String allNotifRead = 'Semua notifikasi telah dibaca';
  static const String failedMarkAllNotif = 'Gagal menandai semua notifikasi';
  static const String failedLoadJobDetail = 'Gagal memuat detail pekerjaan';
  static const String noNotifications = 'Belum ada notifikasi';
  static const String noNotificationsDesc =
      'Notifikasi pekerjaan akan muncul di sini.';
  static const String viewJob = '• Lihat pekerjaan';

  // ── Change Password ────────────────────────────────────────────────────────
  static const String changePasswordTitle = 'Ubah Kata Sandi';
  static const String oldPasswordLabel = 'Kata Sandi Lama';
  static const String oldPasswordHint = 'Masukkan kata sandi saat ini';
  static const String newPasswordLabel = 'Kata Sandi Baru';
  static const String newPasswordHint = 'Minimal 8 karakter';
  static const String confirmPasswordLabel = 'Konfirmasi Kata Sandi Baru';
  static const String confirmPasswordHint = 'Ulangi kata sandi baru';
  static const String oldPasswordEmpty = 'Kata sandi lama wajib diisi';
  static const String newPasswordEmpty = 'Kata sandi baru wajib diisi';
  static const String newPasswordMin = 'Minimal 8 karakter';
  static const String newPasswordSameAsOld =
      'Kata sandi baru tidak boleh sama dengan yang lama';
  static const String confirmPasswordEmpty =
      'Konfirmasi kata sandi wajib diisi';
  static const String confirmPasswordMismatch =
      'Konfirmasi kata sandi tidak sesuai';
  static const String passwordChanged = 'Kata sandi berhasil diubah';

  // ── Profile ────────────────────────────────────────────────────────────────
  static const String editProfileTitle = 'Edit Profil';
  static const String fullNameLabel = 'Nama Lengkap';
  static const String phoneLabel = 'Nomor Telepon';
  static const String phoneHint = '08xxxxxxxxxx';
  static const String phoneEmpty = 'Nomor telepon wajib diisi';
  static const String phoneInvalid = 'Nomor telepon tidak valid';
  static const String saveChanges = 'Simpan Perubahan';
  static const String fromGallery = 'Pilih dari Galeri';
  static const String takePhoto = 'Ambil Foto';
  static const String avatarUpdated = 'Foto profil berhasil diperbarui';
  static const String profileUpdated = 'Profil berhasil diperbarui';

  // ── Empty Jobs ─────────────────────────────────────────────────────────────
  static const String noJobsTitle = 'Tidak ada pekerjaan\ndi tanggal ini';
  static const String noJobsDesc =
      'Tidak ada job yang di-assign\npada tanggal yang dipilih.';

  // ── Job Card ───────────────────────────────────────────────────────────────
  static const String openNavigation = 'Buka Navigasi';
  static const String jobDetail = 'Detail';
  static const String finalItemsTag = 'ITEM SELESAI';
  static const String estimatedItemsTag = 'ESTIMASI ITEM';
  static const String sessionPagi = 'Pagi';
  static const String sessionSiang = 'Siang';
  static const String sessionSore = 'Sore';
  static const String waitingVerification =
      'Menunggu Verifikasi Item dan Invoice';
  static const String jobDone = 'Selesai';
  static const String jobCanceled = 'Pekerjaan Dibatalkan';
  static const String startJob = 'Mulai Pekerjaan';
  static const String finishJob = 'Pekerjaan Selesai';

  // ── Job Detail ─────────────────────────────────────────────────────────────
  static const String jobDetailTitle = 'Detail Pekerjaan';
  static const String sectionOrderer = 'INFORMASI PEMESAN';
  static const String labelOrderer = 'Pemesan';
  static const String labelOrdererPhone = 'No. Pemesan';
  static const String sectionSiteContact = 'KONTAK ORANG DI LOKASI';
  static const String labelSiteContactName = 'Nama';
  static const String labelSiteContactPhone = 'Nomor';
  static const String chatWhatsapp = 'Chat via WhatsApp';
  static const String callPhone = 'Telepon';
  static const String sectionLocation = 'LOKASI';
  static const String labelRegion = 'Wilayah';
  static const String labelAddress = 'Alamat';
  static const String openMaps = 'Buka di Maps';
  static const String sectionStatusSchedule = 'STATUS & JADWAL';
  static const String labelSchedule = 'Jadwal';
  static const String labelStatus = 'Status';
  static const String labelPower = 'Daya';
  static const String sectionNotes = 'CATATAN';
  static const String noNotes = 'Tidak ada catatan.';
  static const String sectionPhotos = 'FOTO ITEM PEKERJAAN';
  static const String noPhotos = 'Belum ada foto item.';
  static const String noItems = 'Belum ada item.';

  // ── Final Items ────────────────────────────────────────────────────────────
  static const String finalItemsTitle = 'Rincian Item Akhir';
  static const String sectionSelectedItems = 'ITEM DIPILIH';
  static const String sectionAdditionalNotes = 'CATATAN TAMBAHAN';
  static const String searchHint = 'Cari item, ukuran… contoh: King, 2×2m';
  static const String additionalNotesHint =
      'Catatan untuk laporan akhir (opsional)';
  static const String addChangeItems = 'Tambah / Ubah Item dari Layanan';
  static const String addItemsDesc =
      'Buka hanya jika ada perubahan atau tambahan item.';
  static const String discountNominalLabel = 'Diskon Nominal';
  static const String dpLabel = 'DP (Down Payment)';
  static const String layananFinal = 'Layanan Final';
  static const String noItemsSelected =
      'Belum ada item.\nPilih dari katalog di bawah.';
  static const String failedLoadCatalog = 'Gagal memuat katalog';
  static const String noMatchingItems = 'Tidak ada item cocok';
  static const String noItemsForService = 'Tidak ada item untuk layanan ini.';
  static const String prefilledBannerSuffix =
      'estimasi item telah dimuat. Edit jumlah atau hapus jika tidak sesuai.';
  static const String submitFinalReport = 'Kirim Laporan Akhir';
}
