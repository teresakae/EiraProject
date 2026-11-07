import Foundation

// DRAFT copy from SAFETY.md. The team can revise wording here without changing the flow.
enum SafetyStrings {
    static let lawyerCaveat = "Bagian jawaban ini belum ditinjau oleh pengacara. Ini informasi umum, bukan nasihat hukum."
    static let privacyTitle = "Tentang catatanmu"
    static let privacy = """
    Catatan disimpan terenkripsi di ponsel dan dibuka dengan frasa sandimu. Tidak ada pemulihan jika kamu lupa.

    Untuk menyusun linimasa, setiap catatan baru dikirim ke AI, apa pun izin penggunaannya. Untuk menjawab pertanyaan atau mengisi draf, teks yang diizinkan dibuka di ponsel lalu dikirim lewat server kami ke OpenAI. Server kami tidak menyimpan salinannya. OpenAI dapat menyimpan teks dan jawaban dalam log pemantauan penyalahgunaan hingga 30 hari.

    Suara diubah menjadi teks, lalu berkas audionya dibuang. Penyamaran hanya mengurangi kemungkinan terlihat sekilas. Penyamaran tidak melindungi dari spyware, akun yang dipakai bersama, atau paksaan membuka ponsel.
    """
    static let confirmationTitle = "Sebelum membuka formulir"
    static let draftNotice = "Draf penjelasan. Bagian tentang proses layanan, hal yang belum diketahui, dan identitas belum ditinjau pengacara. Tim masih perlu menyetujui kata-katanya."
    static let shared = "Hanya isian di bawah yang akan diisi ke formulir. Kata-kata sumbernya ditampilkan agar kamu bisa memeriksa. Catatan yang tidak kamu izinkan untuk laporan tidak disertakan. Tidak ada catatan lain yang dibagikan."
    static let recipient = """
    Penerimanya adalah SAPA 129, layanan KemenPPPA. Layanan ini memulai rujukan ke unit layanan daerah (UPTD PPA), bukan penangkapan dan bukan laporan polisi itu sendiri. Petugas bisa datang ke tempatmu. Untuk risiko tinggi, standar layanan membolehkan kerja sama dengan polisi, RT/RW, atau petugas keamanan. Laporan polisi biasanya menjadi awal perkara pidana. Untuk sebagian tindak pidana, polisi bisa bertindak setelah mengetahuinya; orang lain juga bisa melapor.
    """
    static let sheSends = "Aku hanya mengisi formulir, tidak mengirimnya. Kamu sendiri yang menekan tombol kirim di formulir. Kamu bisa berhenti di sini."
    static let unknowns = """
    Kami tidak tahu apakah atau kapan layanan akan menghubungi suamimu; tidak ditemukan aturan tentang itu. Di atas kertas, standar menyebut respons segera untuk risiko tinggi, sekitar 6 jam untuk risiko sedang, dan dalam 3 hari untuk risiko rendah. Kunjungan ditetapkan pada 1, 2, atau 3 hari. Kami tidak tahu seberapa cepat layanan menjawab dalam praktik. Kamu bisa menolak mediasi yang ditawarkan unit layanan.
    """
    static let risks = "Polisi sering mendorong penyelesaian damai. Dari 105 kasus hukum yang dipantau Komnas Perempuan pada 2025, 18 melibatkan kriminalisasi istri."
    static let anonymity = """
    Situs SAPA punya pilihan tanpa nama dan menyatakan identitas dirahasiakan. Rahasia tidak berarti suamimu tidak akan pernah tahu. Untuk mendapat sebagian bantuan, kamu kemungkinan perlu memberi identitas kepada layanan. Penerimaan layanan meminta nama, alamat, dan kontak; formulir SAPA sendiri meminta nomor telepon. Tanpa nama tidak berarti layanan tidak bisa menghubungimu. Jika perkara masuk pengadilan, suamimu biasanya akan mengetahuinya sebagai pihak dalam perceraian; perkara pidana atau perintah perlindungan juga melibatkannya. Tidak ada sumber yang menjamin namamu bisa disembunyikan darinya.
    """
    static let mockNotice = "Ini formulir uji di ponselmu. Isian tidak dikirim ke SAPA atau ke tempat lain. Tombol kirim hanya menampilkan isian yang diterima formulir uji."
    static let formUnavailable = "Formulir belum bisa diisi. Kamu bisa kembali ke draf dan menyalin tiap isian."
    static let realDeferred = "Pengisian formulir asli belum tersedia. Kamu bisa kembali ke draf dan menyalin tiap isian."

    static func label(_ name: ReportFieldName) -> String {
        switch name {
        case .isVictim: "Siapa yang mengalami"
        case .levelConcern: "Tingkat kekhawatiranmu"
        case .relationshipWithVictim: "Hubungan dengan korban"
        case .incidentTime: "Waktu kejadian"
        case .location: "Tempat kejadian"
        case .provinceCity: "Kota dan provinsi"
        case .description: "Apa yang terjadi"
        case .victimFullName: "Nama korban"
        case .victimGender: "Jenis kelamin korban"
        case .victimAge: "Usia korban"
        case .victimDisabilities: "Korban memiliki disabilitas"
        case .victimDisabilitiesType: "Jenis disabilitas korban"
        case .victimContactNumber: "Nomor telepon korban"
        case .victimTrustedPerson: "Nomor orang dewasa yang dipercaya"
        case .reporterFullName: "Namamu sebagai pelapor"
        case .anonymous: "Tanpa nama"
        case .contactNumber: "Nomor teleponmu"
        }
    }

    static func state(_ status: ReportFieldStatus) -> String {
        switch status {
        case .empty: "Kosong"
        case .fromHerWords: "Dari kata-katamu"
        case .editedByHer: "Diubah olehmu"
        }
    }

    static func choice(_ value: String) -> String {
        switch value {
        case "true": "Ya"
        case "false": "Tidak"
        case "saya_sendiri": "Aku sendiri"
        case "orang_lain": "Orang lain"
        case "sedikit_khawatir": "Sedikit khawatir"
        case "khawatir": "Khawatir"
        case "sangat_khawatir": "Sangat khawatir"
        default: value
        }
    }

    static func display(_ value: ReportValue?) -> String {
        guard let value else { return "Belum diisi" }
        return choice(ReportFields.text(value))
    }
}
