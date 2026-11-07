import Foundation

enum ReportFields {
    static func options(for name: ReportFieldName) -> [String]? {
        switch name {
        case .isVictim: ["saya_sendiri", "orang_lain"]
        case .levelConcern: ["sedikit_khawatir", "khawatir", "sangat_khawatir"]
        case .relationshipWithVictim:
            ["Orang Tidak Dikenal", "Diri Sendiri", "Kenalan Baru", "Pengurus Rumah Tangga", "Guru", "Lainnya",
             "Petugas Layanan", "Petugas Sekolah", "Teman", "Suami/Istri", "Tetangga/ Teman keluarga", "Kerabat",
             "Ayah Kandung", "Ibu Kandung", "Pengasuh Utama", "Anak", "Pacar", "Rekan Kerja", "Atasan / Majikan"]
        case .incidentTime: ["Pagi", "Siang", "Sore", "Malam", "Tidak Diketahui"]
        case .location: ["Rumah Tangga", "Tempat Kerja", "Sekolah/Kampus", "Sarana Umum", "Situasi Darurat/Tempat Bencana", "Daring/Elektronik"]
        case .victimGender: ["laki-laki", "perempuan"]
        case .victimDisabilitiesType:
            ["Mengalami kesulitan melihat, meskipun memakai kacamata",
             "Mengalami kesulitan mendengar, meskipun menggunakan alat bantu dengar",
             "Mengalami kesulitan berkomunikasi, misalnya memahami atau dimengerti",
             "Mengalami kesulitan mengingat atau berkonsentrasi",
             "Mengalami kesulitan dengan perawatan diri seperti membersihkan seluruh tubuh atau berpakaian",
             "Mengalami kesulitan berjalan atau menaiki tangga"]
        default: nil
        }
    }

    static func isBoolean(_ name: ReportFieldName) -> Bool {
        name == .victimDisabilities || name == .anonymous
    }

    static func isPhone(_ name: ReportFieldName) -> Bool {
        [.victimContactNumber, .victimTrustedPerson, .contactNumber].contains(name)
    }

    static func text(_ value: ReportValue?) -> String {
        switch value {
        case .text(let text): text
        case .integer(let number): String(number)
        case .boolean(let flag): flag ? "true" : "false"
        case nil: ""
        }
    }

    static func valid(_ value: ReportValue?, for name: ReportFieldName) -> Bool {
        guard let value else { return true }
        if isBoolean(name) {
            if case .boolean = value { return true }
            return false
        }
        if name == .victimAge {
            if case .integer(let age) = value { return (1...100).contains(age) }
            return false
        }
        guard case .text(let text) = value, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              text.count <= 5000 else { return false }
        if let options = options(for: name) { return options.contains(text) }
        if isPhone(name) { return text.allSatisfy { $0 >= "0" && $0 <= "9" } }
        return true
    }

    static func editedValue(_ text: String, for name: ReportFieldName) -> ReportValue? {
        if text.isEmpty { return nil }
        if isBoolean(name), let flag = Bool(text) { return .boolean(flag) }
        if name == .victimAge, let age = Int(text) { return .integer(age) }
        return .text(text)
    }

    static func checked(_ draft: ReportDraft, entries: [Entry]) -> ReportDraft {
        ReportDraft(fields: ReportFieldName.allCases.map { name in
            let field = draft.fields.first { $0.fieldName == name } ?? ReportDraftField(fieldName: name)
            guard valid(field.value, for: name) else { return ReportDraftField(fieldName: name) }
            return QuoteCheck.validated(field, against: entries)
        })
    }

    static func merged(_ response: DraftResponse, keeping draft: ReportDraft, entries: [Entry]) -> ReportDraft {
        checked(ReportDraft(fields: ReportFieldName.allCases.map { name in
            if let edited = draft.fields.first(where: { $0.fieldName == name && $0.status == .editedByHer }) { return edited }
            let pair = response.fields[name]
            return ReportDraftField(fieldName: name, value: pair?.value, quote: pair?.quote)
        }), entries: entries)
    }

    static func missingRequired(in draft: ReportDraft) -> Set<ReportFieldName> {
        var required: Set<ReportFieldName> = [.isVictim, .levelConcern, .relationshipWithVictim, .incidentTime,
            .location, .provinceCity, .description, .victimGender, .victimAge, .victimDisabilities]
        if draft.fields.first(where: { $0.fieldName == .victimDisabilities })?.value == .boolean(true) {
            required.insert(.victimDisabilitiesType)
        }
        if draft.fields.first(where: { $0.fieldName == .anonymous })?.value != .boolean(true) {
            required.insert(.reporterFullName)
        }
        return required.filter { name in
            guard let value = draft.fields.first(where: { $0.fieldName == name })?.value else { return true }
            return !valid(value, for: name)
        }
    }
}
