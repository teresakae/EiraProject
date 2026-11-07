import Foundation

// DRAFT copy from SAFETY.md. The team can revise wording here without changing the flow.
enum SafetyStrings {
    static let lawyerCaveat = "This part of the answer has not been reviewed by a lawyer. It is general information, not legal advice."
    static let privacyTitle = "Where your words go"
    static let privacy = """
    Your entries are encrypted on this phone with a key held by this device. Access uses a fixed PIN. Anyone who can use your unlocked phone and knows Eira and the PIN can open your entries.

    Every new diary entry is sent to AI to build your timeline, regardless of its allowed uses. To answer questions or fill a draft, permitted text is decrypted on your phone and sent through our server to OpenAI. Our server keeps no copy. OpenAI may retain text and replies in abuse-monitoring logs for up to 30 days.

    Audio is transcribed, then deleted. The disguise only reduces casual discovery. It does not protect against spyware, shared accounts, or being forced to unlock your phone.
    """
    static let confirmationTitle = "Before opening the form"
    static let draftNotice = "Draft explanation. The sections on the service process, unknowns and identity have not been reviewed by a lawyer. The team still needs to approve the wording."
    static let shared = "Only the fields above will be filled into the form. Your source words are shown so you can check them. Entries you have excluded from report use are not included. No other entries are shared."
    static let recipient = """
    The recipient is SAPA 129, a KemenPPPA service. It starts a referral to a regional service unit (UPTD PPA); it is not itself an arrest or a police report. Staff may visit you. For high-risk cases, service standards allow coordination with police, neighbourhood officials, or security staff. A police report usually starts a criminal case. For some offences, police can act after learning about them; other people can also report.
    """
    static let sheSends = "I only fill the form; I do not send it. You press the form’s own send button. You can stop here."
    static let unknowns = """
    We do not know whether or when the service will contact your husband; no rule on this was found. Published standards specify an immediate response for high risk, around 6 hours for medium risk, and within 3 days for low risk. Visits are scheduled within 1, 2, or 3 days. We do not know how quickly the service responds in practice. You can decline mediation offered by the service unit.
    """
    static let risks = "Police often encourage settlement. Of 105 legal cases monitored by Komnas Perempuan in 2025, 18 involved wives facing criminalisation."
    static let anonymity = """
    The SAPA site offers an anonymous option and says identities are confidential. Confidential does not mean your husband will never find out. Some assistance may require you to identify yourself to the service. Intake asks for a name, address and contact details; the SAPA form has a phone number field, which you can leave empty. Anonymous does not mean the service cannot contact you. If a case reaches court, your husband will usually know as a party to a divorce; criminal proceedings or protection orders also involve him. No source guarantees your identity can be hidden from him.
    """
    static let mockNotice = "This is a test form on your phone. Nothing is sent to SAPA or anywhere else. Its send button only displays the fields received by the test form."
    static let reportTitle = "Your report draft"
    static let reportIntro = "Filled from your diary and what you told Eira. Check it, change it, or stop here."
    static let reportReachTitle = "How can SAPA reach you?"
    static let reportReachNote = "SAPA sends updates by WhatsApp and can also call. SAPA’s form has no space for this, so if you pick an option, it is added to your description. You will see it before anything opens. To name safe times, add them to your description."
    static func contactLine(_ preference: ReportFlow.ContactPreference) -> String? {
        switch preference {
        case .noPreference: nil
        case .noWhatsApp: "Mohon jangan kirim pesan WhatsApp. Hubungi lewat telepon saja."
        case .whatsAppOK: "Mohon hubungi lewat pesan saja, jangan telepon."
        }
    }
    static func fieldNote(_ name: ReportFieldName) -> String? {
        switch name {
        case .contactNumber: "SAPA may use this number for WhatsApp messages or calls. You can leave it empty, but then SAPA may have no way to reach you."
        case .victimContactNumber: "SAPA may use this number for WhatsApp messages or calls. You can leave it empty."
        case .victimTrustedPerson: "SAPA may call this person first. Check with them before adding their number."
        default: nil
        }
    }
    static let referencesNotSent = "For your information. These references are not added to the form. "
    static let reviewTitle = "This is what SAPA 129 will get"
    static let reviewIntro = "These fields fill the form. Tap any part to change it."
    static let neverSends = "Eira never sends anything for you."
    static let afterSendTitle = "Did you send the form?"
    static let afterSendIntro = "Eira can’t see whether it was sent. Tell us, so the next steps match what happened."
    static let afterSendConfirmed = "You sent it yourself. Eira did not send anything."
    static let nextStepsHeading = "WHAT MAY HAPPEN NEXT"
    static func nextSteps(contact: ReportFlow.ContactPreference) -> [(title: String, detail: String)] {
        let asked = switch contact {
        case .noPreference: ""
        case .noWhatsApp: "You asked for calls, not WhatsApp messages. "
        case .whatsAppOK: "You asked for WhatsApp messages, not calls. "
        }
        return [("SAPA 129 may reply",
          asked + "We do not know how fast they answer in practice."),
         ("They can connect you with services",
          "Such as counselling, legal aid or temporary shelter. What exists varies by area. Staff may visit, and in high-risk cases may involve police."),
         ("You can say no to mediation",
          "Ask what each step means before you agree. Some steps, such as police action on some offences, may not depend on you.")]
    }
    static let keepRecordsTitle = "Keep your diary and report?"
    static let keepRecordsDetail = "Saved encrypted on this phone. Our server keeps no copy."
    static let deleteConfirmTitle = "Delete your diary and report? This cannot be undone."
    static let trackerLink = "See where a report is"
    static let trackerTitle = "Where your report is"
    static let trackerNotice = "Sample preview. Live tracking would come through a collaboration with SAPA 129. This is not a real report, and nothing here comes from SAPA."
    static let trackerReference = "SAMPLE-0129"
    static let trackerStages: [(title: String, detail: String)] = [
        ("Sent", "You sent the form yourself."),
        ("Received by SAPA 129", "SAPA 129 has your report."),
        ("Referred to a service unit", "SAPA 129 passed it to a regional service unit (UPTD PPA). A referral is not an arrest."),
        ("Service unit contacts you", "Staff may contact or visit you. In high-risk cases they may involve police."),
        ("Support arranged", "Such as counselling, legal aid or temporary shelter. What exists varies by area. You can say no to mediation.")
    ]
    static let trackerFootnote = "Not every report follows these steps in this order. We do not know how fast each step happens in practice."
    static let formUnavailable = "The form could not be filled. You can return to your draft and copy each field."
    static let realDeferred = "Filling the live form is not available yet. You can return to your draft and copy each field."

    static let talkAskFirst = "Can I ask a few things so I get it right? You can skip any question."
    static let talkNoStory = "You can tell me what happened, or ask about your options. You can skip any question."
    static func talkOpening(entryDate: Date?) -> String {
        guard let entryDate else { return talkNoStory }
        return "I read your diary entry from \(entryDate.formatted(.dateTime.day().month(.abbreviated))). \(talkAskFirst)"
    }
    static func factLabel(_ category: TalkFactCategory) -> String {
        switch category {
        case .who: "Person"
        case .what: "What"
        case .when: "When"
        case .where: "Place"
        }
    }
    static let summaryTitle = "Here’s what Eira understood"
    static let summaryIntro = "From your diary and your talk. Fix anything that isn’t right."
    static let summaryEmpty = "Not noted yet"
    static let legalHeading = "POSSIBLY RELEVANT LEGAL REFERENCES"
    static let legalBecause = "This may be relevant because"
    static let legalConsequence = "Possible legal consequence under this law can vary. Learn more with a lawyer or LBH."
    static let legalFootnote = "General information, not legal advice. These references have not been reviewed by a lawyer. A lawyer or LBH can confirm what fits your case."

    static func label(_ name: ReportFieldName) -> String {
        switch name {
        case .isVictim: "Who experienced this"
        case .levelConcern: "Your level of concern"
        case .relationshipWithVictim: "Relationship to the person affected"
        case .incidentTime: "When it happened"
        case .location: "Where it happened"
        case .provinceCity: "City and province"
        case .description: "What happened"
        case .victimFullName: "Name of person affected"
        case .victimGender: "Gender of person affected"
        case .victimAge: "Age of person affected"
        case .victimDisabilities: "Person affected has a disability"
        case .victimDisabilitiesType: "Type of disability"
        case .victimContactNumber: "Phone number of person affected"
        case .victimTrustedPerson: "Trusted adult’s phone number"
        case .reporterFullName: "Your name as the person reporting"
        case .anonymous: "Anonymous"
        case .contactNumber: "Your phone number"
        }
    }

    static func state(_ status: ReportFieldStatus) -> String {
        switch status {
        case .empty: "Empty"
        case .fromHerWords: "From your words"
        case .editedByHer: "Edited by you"
        }
    }

    static func choice(_ value: String) -> String {
        switch value {
        case "true": "Yes"
        case "false": "No"
        case "saya_sendiri": "Me"
        case "orang_lain": "Someone else"
        case "sedikit_khawatir": "A little concerned"
        case "khawatir": "Concerned"
        case "sangat_khawatir": "Very concerned"
        case "Orang Tidak Dikenal": "Stranger"
        case "Diri Sendiri": "Self"
        case "Kenalan Baru": "New acquaintance"
        case "Pengurus Rumah Tangga": "Domestic worker"
        case "Guru": "Teacher"
        case "Lainnya": "Other"
        case "Petugas Layanan": "Service worker"
        case "Petugas Sekolah": "School staff"
        case "Teman": "Friend"
        case "Suami/Istri": "Spouse"
        case "Tetangga/ Teman keluarga": "Neighbour / family friend"
        case "Kerabat": "Relative"
        case "Ayah Kandung": "Biological father"
        case "Ibu Kandung": "Biological mother"
        case "Pengasuh Utama": "Primary caregiver"
        case "Anak": "Child"
        case "Pacar": "Partner"
        case "Rekan Kerja": "Colleague"
        case "Atasan / Majikan": "Supervisor / employer"
        case "Pagi": "Morning"
        case "Siang": "Midday"
        case "Sore": "Afternoon"
        case "Malam": "Night"
        case "Tidak Diketahui": "Unknown"
        case "Rumah Tangga": "Home"
        case "Tempat Kerja": "Workplace"
        case "Sekolah/Kampus": "School / campus"
        case "Sarana Umum": "Public place"
        case "Situasi Darurat/Tempat Bencana": "Emergency / disaster location"
        case "Daring/Elektronik": "Online / electronic"
        case "laki-laki": "Male"
        case "perempuan": "Female"
        case "Mengalami kesulitan melihat, meskipun memakai kacamata": "Difficulty seeing, even with glasses"
        case "Mengalami kesulitan mendengar, meskipun menggunakan alat bantu dengar": "Difficulty hearing, even with a hearing aid"
        case "Mengalami kesulitan berkomunikasi, misalnya memahami atau dimengerti": "Difficulty communicating, understanding or being understood"
        case "Mengalami kesulitan mengingat atau berkonsentrasi": "Difficulty remembering or concentrating"
        case "Mengalami kesulitan dengan perawatan diri seperti membersihkan seluruh tubuh atau berpakaian": "Difficulty with self-care, such as washing or dressing"
        case "Mengalami kesulitan berjalan atau menaiki tangga": "Difficulty walking or climbing stairs"
        default: value
        }
    }

    static func display(_ value: ReportValue?, for name: ReportFieldName) -> String {
        guard let value else { return "Not filled in" }
        let text = ReportFields.text(value)
        return ReportFields.options(for: name) != nil || ReportFields.isBoolean(name) ? choice(text) : text
    }
}
