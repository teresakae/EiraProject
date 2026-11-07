# Legal review log

Date of research: 6 November 2026. Companion to `LEGAL_FAQ.md`.

**This research was done by an AI. No lawyer has reviewed it.** It is not legal advice. The FAQ must not be called lawyer-checked. Nothing here changes the FAQ until the team approves it. If the team ever reaches a lawyer, this log shows where to start.

## How to read this

Each finding has a grade:

- **PRIMARY:** the AI read the official text.
- **SECONDARY:** a reputable source described it, or the AI read an unofficial copy of the text.
- **NOT FOUND:** the AI could not confirm it.

One limit affects a lot of this log. The official PDFs of the new KUHAP (UU 20/2025) and of UU 1/2026 were too large to open. Those laws and the new KUHP (UU 1/2023) were read on pasal.id. It names peraturan.go.id as its source, but it is not an official site. It marks some text as unreviewed, and some pages have scanning errors. All of that is graded SECONDARY, even where the article text was read word by word. Someone should compare the key articles against the official PDFs.

"Statute" below means what the text says. "Practice" means what is reported to happen. They often differ.

## Decisions needed before the demo

1. **Do not load `LEGAL_FAQ.md` into the AI as it stands.** It now holds research notes and unapproved text. `CODEX_PROMPTS.md` and `AGENTS.md` point builders to this file as the grounding text. The AI should get approved answers only.
2. **Decide on the four warned passages:** answers 2, 3, 9 and 12. Each is marked in the FAQ. Until the team decides, they should not reach her.
3. **Decide on the 6-month point in answer 11.** It is not marked as a warning, because each sentence in the original holds. It is still the biggest gap.
4. **Decide whether to widen the caveat.** Plain code adds a lawyer caveat for answers 4, 7 and 11 (`AI_CONTRACTS.md`, line 91). No answer has had lawyer review. Answers 2, 3, 9 and 12 now have warnings, so the team may want the caveat on those too.

## Highest-risk findings

These are the points most likely to mislead her, most serious first.

1. **Answer 11 leaves out a filing deadline.** Under KUHP Pasal 29, a complaint can be made within 6 months of when the person knew of the offence. "Light" spousal violence, light psychological violence and marital sexual violence all need her complaint. Eira is built for women who are not ready to report. A woman who waits could lose an option without knowing it. Grade: SECONDARY. Application to PKDRT is a reading of KUHP Pasal 187, not a confirmed ruling.
2. **Answer 2 promises something no source supports.** It says she gives her identity to the service "but not to your husband", and it lists a court case in the same sentence. In a divorce he is the other party. A criminal case or a protection order also involves him. This is an inference from how those cases work, but no source says her name can be kept from him. `SAFETY.md` line 50 repeats the wording.
3. **Answer 1 and the service standard: someone may come, and police may be involved.** The national service standard (Permen PPPA 2/2022) lets staff trace an address and go to where a person is. It lets staff work with police, RT/RW and security officers in high-risk cases. Reports can come from third parties. A woman told "not automatically" may not expect this, and a visit could reach a home she shares with him. Grade: PRIMARY for the standard. Practice in Bekasi: NOT FOUND. The team may also want to check how the SAPA form handles a safe way to reach her. `SAPA_FORM.md` shows phone number fields, and SAPA's own form requires one, so "anonymous" may not mean unreachable.
4. **Answer 9 says the visum is "usually free".** No data supports "usually". The rule on paper says UPTD PPA services are not charged to her. But 2026 reports describe victims paying, and sources conflict on BPJS. She could arrive with no money and be charged.
5. **Answer 12 says no national rule on length of stay was found.** One exists: a maximum of 14 days in a UPTD PPA temporary shelter, then referral elsewhere. She might plan around an open-ended stay. Grade: PRIMARY.
6. **Answer 3 opens with "Yes."** That is a verdict the law leaves to the authorities, and it breaks the non-judging rule. The articles it cites are correct.
7. **Answer 4 and the research pack on restorative justice.** The pack's note that Pasal 44(1) "appears excluded" should be reversed for courts, because Supreme Court guidance quoted in secondary sources says a 5-year offence is not excluded. So a report of hitting at the 44(1) level may also be offered a settlement.
8. **The pack's "pre-trial detention looks unlikely" is too broad.** Pasal 44(1) meets the 5-year threshold on its face. The answer differs by offence. Whether he could be held affects her safety and income, so the FAQ should not imply either result.
9. **Answer 8 on recordings is overstated.** "Generally treated as usable evidence" rests mainly on a 2017 article. The law has changed since then, and sources conflict.
10. **Older statements now known to be wrong or incomplete.** The pack and `SAFETY.md` line 48 say no response time was found. The service standard has one (see section 5, answer 1). The pack's line on withdrawing a report only after an agreement is carried out applies inside the restorative justice process, not to every withdrawal.

## 1. Answers 4, 7 and 11: 2026 changes

### Restorative justice under the new KUHAP

**Finding (statute).** The rules are in KUHAP Pasal 79 to 88 and Pasal 204. An agreement can include forgiveness, compensation and repair. It must be carried out within 7 days. If it is not, the case can continue. It can be started by either side or offered by an investigator, prosecutor or judge. It must be free of pressure, coercion, intimidation, deception and threats. The victim signs it. At the investigation stage, a court ruling follows within days. It is not available for sexual violence or for several other listed offences.

**Finding (practice).** Commentators and women's groups worry about pressure and about case-trading. Hukumonline (May 2026) describes gaps in the rules. Courts have applied the mechanism in other kinds of case. A [Supreme Court news report](https://marinews.mahkamahagung.go.id/berita/pn-donggala-berhasil-terapkan-mekanisme-keadilan-restoratif-0bcD) describes a theft case at PN Donggala, seen only as a search summary. No source shows how it is working in KDRT cases.

**Grade:** SECONDARY.

**Sources:** [KUHAP Pasal 79](https://pasal.id/peraturan/uu/uu-no-20-tahun-2025/pasal-79), [80](https://pasal.id/peraturan/uu/uu-no-20-tahun-2025/pasal-80), [81](https://pasal.id/peraturan/uu/uu-no-20-tahun-2025/pasal-81), [82](https://pasal.id/peraturan/uu/uu-no-20-tahun-2025/pasal-82), [83](https://pasal.id/peraturan/uu/uu-no-20-tahun-2025/pasal-83), [204](https://pasal.id/peraturan/uu/uu-no-20-tahun-2025/pasal-204); [Hukumonline, May 2026](https://www.hukumonline.com/berita/a/restorative-justice-dalam-kuhap-baru-dinilai-masih-menyisakan-banyak-celah-lt69fc7d392438f/); [Kompas, Jan 2026](https://nasional.kompas.com/read/2026/01/04/08395171/mencermati-pasal-keadilan-restoratif-dalam-kuhap-baru); [Komnas Perempuan chair via Hukumonline, Mar 2026](https://www.hukumonline.com/berita/a/implementasi-uu-tpks-harus-utamakan-perlindungan-korban--bukan-mediasi-damai-lt69a6685ecfb26).

**Unknown.** KUHAP Pasal 204(7) requires, at trial, no "ketimpangan relasi kuasa" (power imbalance) between victim and defendant. That could matter a lot for spouses. No source says how it applies. It appears only in the trial article, not in Pasal 80 to 85.

**Tension to flag.** The 2022 service standard (lampiran p. 40) tells companions that violence against women is not a matter for restorative justice at the investigation and pre-prosecution stages. That predates the new KUHAP. No source reconciles them.

**Lawyer's first check:** how Pasal 204(7) and Pasal 80 apply to a husband and wife.

### Withdrawing a complaint

**Finding (statute).** KUHP Pasal 29 gives 6 months to file a complaint from when the person knows of the offence (9 months if abroad). Pasal 30 lets the complaint be withdrawn within 3 months of filing, and a withdrawn complaint cannot be filed again. Pasal 187 applies the general rules to offences in other laws unless a law says otherwise. PKDRT Pasal 51 to 53 make 44(4), 45(2) and spousal 46 complaint offences, and PKDRT sets no time limit of its own. UU 1/2026 lists 55 changes to the KUHP, and Pasal 29, 30 and 187 are not among them.

**Conflict.** KUHP Pasal 30 allows withdrawal within 3 months. KUHAP Pasal 79(4) says that in a restorative justice process a report can be withdrawn only after the agreement is fully carried out. No source resolves how they fit.

**Grade:** PRIMARY for PKDRT. SECONDARY for KUHP and KUHAP.

**Sources:** [KUHP Pasal 29](https://pasal.id/peraturan/uu/uu-no-1-tahun-2023/pasal-29), [30](https://pasal.id/peraturan/uu/uu-no-1-tahun-2023/pasal-30), [187](https://pasal.id/peraturan/uu/uu-no-1-tahun-2023/pasal-187); [UU 1/2026](https://pasal.id/peraturan/uu/uu-no-1-tahun-2026); [Hukumonline, Nov 2025](https://www.hukumonline.com/berita/a/pengaduan-kuhp-baru-lt69114de635f87?page=all). Hukumonline's page appears to place the no-refile rule under Pasal 29, while the statute copy has it in Pasal 30(2).

**Unknown.** No source applies the 6-month limit to PKDRT by name. It is also unclear how it is counted when violence is repeated, and whether each event has its own period. The earlier note on Supreme Court ruling 1600 K/Pid/2009 (withdrawal after 3 months allowed) was not confirmed and predates the new code.

**Lawyer's first check:** does Pasal 29 apply to PKDRT complaint offences, and how is it counted for repeated acts?

### Protection orders

**Finding (statute).** UU 23/2004 Pasal 16, 28 to 32 and 35 to 38 say what answer 7 says, with three additions. The court can decline for a "proper reason" (Pasal 28). She can apply herself, and a third party needs her consent except in certain circumstances (Pasal 30). The police duty starts when they know or receive a report (Pasal 16). Pasal 54 says PKDRT procedure stands unless the Act says otherwise. KUHP Pasal 622 as read does not mention UU 23/2004, but UU 1/2026 amended that article and the amended text was not read.

**Finding (practice).** A UGM thesis says authorities tend to give only temporary protection and that court orders are rarely or never applied, mainly for lack of implementing rules. LBH APIK says the 24-hour protection is often not given. No yearly count was found.

**Grade:** PRIMARY for the statute. SECONDARY for practice. Some practice sources were read only at search-result level.

**Sources:** [UU 23/2004 PDF](https://peraturan.bpk.go.id/Download/30306/UU%20Nomor%2023%20Tahun%202004.pdf); [UGM thesis](https://etd.repository.ugm.ac.id/penelitian/detail/237097); [Kompas, LBH APIK](https://www.kompas.id/artikel/dua-dekade-uu-penghapusan-kdrt-gurita-kekerasan-terus-membelenggu-perempuan-dan-anak); [Konde](https://www.konde.co/2025/04/korban-kdrt-berhak-dapat-perlindungan-sementara-yuk-simak-gimana-caranya/); [Magdalene](https://magdalene.co/story/restraining-order-untuk-lindungi-korban-kdrt-sebuah-pembelajaran/); [DPR Info Singkat, Jan 2025](https://berkas.dpr.go.id/pusaka/files/info_singkat/Info%20Singkat-XVII-1-I-P3DI-Januari-2025-214.pdf).

**Unknown.** Whether the new KUHAP changes how the order or the arrest power works, how often orders are issued, and whether any court in Bekasi issues them.

**Lawyer's first check:** whether Pengadilan Negeri Bekasi accepts direct applications from a wife in practice.

## 2. Answer 3: the proposed reword

**Finding.** The reword in the FAQ is accurate and removes the verdict. Its article references are right. It can be better in four ways. It does not answer "he doesn't hit me every day". The texts of Pasal 6 and 7 do not say an act must be frequent. It says "under his control" where Pasal 9 says the person doing it. It leaves out "or a fine" in Pasal 49. It also omits Pasal 8 and Pasal 9(1). A fuller version is in the FAQ. It does not say her husband did anything, it applies no sentence to him, and it tells her to do nothing.

**Grade:** PRIMARY.

**Source:** [UU 23/2004 PDF](https://peraturan.bpk.go.id/Download/30306/UU%20Nomor%2023%20Tahun%202004.pdf).

**Unknown.** Whether courts require any level of repetition in practice. No case law was checked.

**Lawyer's first check:** whether "does not say it has to happen often" is a fair statement, given how courts read Pasal 6 and 7.

## 3. Answer 12: recommendation

**Recommendation: keep it, using the corrected text.** The team decides.

- It answers a question a woman in this position will ask. Without it, the AI has to say the FAQ does not cover it.
- It rests on a law and a national standard that were read directly.
- It holds real unknowns honestly.
- The original needs one fix: the 14-day limit.

**Finding (statute).** UU 23/2004 Pasal 22 covers rumah aman and other housing. Permen PPPA 2/2022 lampiran 3.2.4 (pp. 36 to 38) sets a maximum of 14 days in UPTD PPA temporary shelter, then referral to a safe house, a social institution or LPSK, based on assessment. It requires a consent form and 24-hour guards. It says location must put safety from the perpetrator first, and shelter can be given before a protection order. Perpres 55/2024 requires cities and regencies to form a UPTD PPA, with no deadline shown.

**Finding (practice).** Availability is uneven. Some areas have none. The standard itself says it depends on what exists in each area.

**Grade:** PRIMARY for the standard and Pasal 22. SECONDARY for Perpres 55/2024 and for practice.

**Sources:** [Permen PPPA 2/2022](https://peraturan.go.id/files/bn85-2022.pdf); [Perpres 55/2024](https://pasal.id/peraturan/perpres/perpres-no-55-tahun-2024); [Undip journal](https://ejournal.undip.ac.id/index.php/mmh/article/viewFile/33990/19314); [2026 thesis naming UPTD PPA Kota Bekasi](https://digilib.uinsgd.ac.id/137193/).

**Unknown.** Whether a mother's children may stay with her: the standard covers women and children but no explicit rule was found. Whether either Bekasi unit has a shelter. Whether 14 days is applied strictly. This needs a phone call, not a lawyer.

**Safety note for the team.** The research pack notes that leaving can be the most dangerous period. The FAQ must not tell her to leave or stay. If the team wants safety planning around leaving, it belongs in `SAFETY.md` with a human service. This research did not assess that.

**Lawyer's first check:** whether Perpres 55/2024 changes any part of the 2018 and 2022 ministerial rules.

## 4. Open lawyer items

### Is Pasal 44(1) eligible for restorative justice?

**Finding.** The statute wording conflicts on its face. KUHAP Pasal 80(1)(a) says "paling lama 5 tahun" (at most 5 years). Pasal 82 and Pasal 204(5)(a) exclude "5 (lima) tahun atau lebih" (5 years or more). Secondary sources quote SEMA 1/2026, Lampiran III angka 2 huruf b, as saying a 5-year offence can go through and is "tidak dikecualikan" (not excluded). A commentator notes the SEMA binds courts internally. Prosecutors reportedly read the rule more narrowly. The head of the district court must approve a settlement, and one May 2026 commentary, seen only as a search summary, describes a head rejecting a request. So inference, not finding: Pasal 44(1) is likely eligible in court.

**Grade:** SECONDARY. Official SEMA text: NOT FOUND. A search limited to the Supreme Court's domain returned only commentary.

**Sources:** [Harris Manaloe](https://www.harrismanaloe.com/2026/02/sema-12026-tentang-mekanisme-keadilan.html); [Dandapala](https://dandapala.com/article/detail/sema-12026-ketua-pn-jadi-penentu-kunci-restorative-justice); [Lativi News](https://lativinews.com/mekanisme-keadilan-restoratif-dalam-perkara-pencurian-harmonisasi-melalui-sema-nomor-1-tahun-2026/).

**Unknown.** Whether police and prosecutors follow it. Whether it holds in a KDRT case. No source applies it to KDRT by name.

**Lawyer's first check:** the official SEMA 1/2026 text, then what prosecutors in Bekasi do.

### Implementing regulation for restorative justice (KUHAP Pasal 88)

**Finding.** NOT FOUND as issued. As of March 2026 it was not out. A Hukumonline piece from spring 2026 described it as awaiting the President. A Supreme Court justice was reported in May 2026 as saying it was still not issued. A July 2026 article still treated it as a future rule. The Hukumonline piece and the July article were seen only as search summaries. Searches found nothing later. The peraturan.go.id regulation list could not be checked directly, so it may have been issued without being found.

**Grade:** SECONDARY.

**Sources:** [Hukumonline Klinik, Mar 2026](https://www.hukumonline.com/klinik/a/restorative-justice-dalam-kuhap-baru-lt519065e9ed0a9); [Hukumonline, awaiting rules](https://www.hukumonline.com/berita/a/menanti-terbitnya-aturan-turunan-kuhap-baru-lt69e79a55bbdfe/); [Kumparan opinion, May 2026](https://kumparan.com/faradiva-rosyandra-tanjung/keadilan-restoratif-butuh-kepastian-bukan-sekadar-semangat-28SJjlXT24t).

**Lawyer's first check:** whether it now exists. Anyone could check this at peraturan.go.id.

### Fine conversions under UU 1/2026

**Finding.** Pasal II(5) converts prison-plus-fine provisions in laws outside the KUHP into fine categories by prison length. The KUHP fine categories are in Pasal 79. PKDRT is not named on the page read, and the attachment was not visible. Applying the general rule gives the AI's own working:

| PKDRT article | Prison maximum (unchanged) | Likely fine category | Amount |
|---|---|---|---|
| 44(1) | 5 years | IV | Rp200m |
| 44(2) | 10 years | VI | Rp2b |
| 44(3) | 15 years | VII | Rp5b |
| 44(4) | 4 months | II | Rp10m |
| 45(1) | 3 years | III | Rp50m |
| 45(2) | 4 months | II | Rp10m |
| 46 | 12 years | VII | Rp5b |
| 49 | 3 years | III | Rp50m |

This table is inference, not a finding. The FAQ states no rupiah amounts, so nothing needs changing there. Do not quote the old amounts in UU 23/2004, and do not quote these. Pasal I of UU 1/2026 removes special minimum penalties in laws outside the KUHP, with listed exceptions. PKDRT Pasal 47 and 48 have minimums. How this affects them, and whether it matters for KUHAP Pasal 82's "special minimum" exclusion, was not resolved.

**Grade:** SECONDARY.

**Sources:** [UU 1/2026](https://pasal.id/peraturan/uu/uu-no-1-tahun-2026); [KUHP Pasal 79](https://pasal.id/peraturan/uu/uu-no-1-tahun-2023/pasal-79).

**Lawyer's first check:** the UU 1/2026 attachment, for any line on UU 23/2004.

### Pre-trial detention under the new KUHAP

**Finding (statute).** Pasal 100(1) allows detention for offences of 5 years or more. Pasal 100(2) adds a list of KUHP articles. No PKDRT article is on it. Pasal 100(5) also requires two valid pieces of evidence and one of eight grounds, such as trying to flee or repeating the offence. Hukumonline reads (5) as additional to the threshold. So 44(1), 44(2), 44(3) and 46 meet the threshold on their face, and 44(4), 45(1), 45(2) and 49 appear not to. That second part is inference. Separately, PKDRT Pasal 35, 36 and 38 give arrest and detention powers for breaking a protection order.

**Grade:** SECONDARY.

**Sources:** [KUHAP Pasal 100](https://pasal.id/peraturan/uu/uu-no-20-tahun-2025/pasal-100); [Hukumonline, Jan 2026](https://www.hukumonline.com/berita/a/begini-prosedur-dan-syarat-aph-melakukan-penahanan-dalam-kuhap-baru-lt6977289eebfa8).

**Unknown.** A challenge at the Constitutional Court (285/PUU-XXIV/2026) targets parts of Pasal 100(5). Its status was not checked. Practice in KDRT cases was not found.

**Lawyer's first check:** whether Pasal 44(1) detention is used in practice, and the status of that challenge.

### Recording conversations, and her own ITE risk

**Finding.** The Constitutional Court (20/PUU-XIV/2016) said electronic information as evidence must, specifically ("khususnya"), be obtained for law enforcement at the request of the authorities. It added that word so as not to narrow the wider meaning of the evidence rule. It does not directly address a private person recording her own conversation. A 2017 Hukumonline article says a participant's live recording is not interception and can be evidence, but she can still be sued civilly. Other writers read the ruling to require consent or a request from the authorities. **These sources conflict.** New KUHAP Pasal 235 bars evidence obtained unlawfully. KUHP Pasal 258 penalises unlawfully recording non-public electronic transmissions, with no express carve-out for a participant. So phone-call recording is a bigger question than recording a conversation in a room. Reading it that way is inference.

**Her own risk.** UU ITE Pasal 27A and KUHP Pasal 441 cover attacks on honour. Komnas Perempuan's 18 of 105 cases show that criminalising wives is a real pattern, as the FAQ states.

**Grade:** PRIMARY for the court ruling. SECONDARY for the rest.

**Sources:** [MK 20/PUU-XIV/2016](https://www.mkri.id/public/content/persidangan/putusan/20_PUU-XIV_2016.pdf); [Hukumonline 2017](https://www.hukumonline.com/klinik/a/bisakah-rekaman-diam-diam-percakapan-telepon-dijadikan-alat-bukti-lt59c1ebe5c1c71/); [Binus](https://business-law.binus.ac.id/2016/11/22/kedudukan-cctv-sebagai-alat-bukti-hukum-pidana-pasca-putusan-mk-2016/); [Klaussa](https://www.klaussa.com/blog/hukum-merekam-percakapan-diam-diam-untuk-bukti); [KUHP Pasal 258](https://pasal.id/peraturan/uu/uu-no-1-tahun-2023/pasal-258); [KUHP Pasal 622](https://pasal.id/peraturan/uu/uu-no-1-tahun-2023/pasal-622); [UU ITE Pasal 27A](https://pasal.id/peraturan/uu/uu-no-1-tahun-2024/pasal-27a).

**Unknown.** No source deals with a KDRT victim recording her husband. How UU 1/2024 and KUHP Pasal 622 fit together was not resolved.

**Lawyer's first check:** can she safely record a conversation she is in, and does a phone call differ from a room?

### Marital rape

**Finding.** Three texts overlap. PKDRT Pasal 46 and 53: up to 12 years or a fine, on complaint. KUHP Pasal 473(1) and (6): up to 12 years, prosecuted only on the victim's complaint. TPKS Pasal 4(2)(h) lists sexual violence in the household as a TPKS offence. **No source says which prevails.** Academic pieces discuss the special-law principle and alternative charges, but none covers KUHP 473(6). Two points hold under all three: restorative justice is excluded, and PKDRT and KUHP both need her complaint. What is unclear is how a withdrawn complaint fits with TPKS Pasal 23.

**Grade:** PRIMARY for PKDRT. SECONDARY for KUHP and TPKS. Priority between them: NOT FOUND.

**Sources:** [KUHP Pasal 473](https://pasal.id/peraturan/uu/uu-no-1-tahun-2023/pasal-473); [TPKS Pasal 4](https://pasal.id/peraturan/uu/uu-no-12-tahun-2022/pasal-4), [Pasal 23](https://pasal.id/peraturan/uu/uu-no-12-tahun-2022/pasal-23).

**Lawyer's first check:** which law prosecutors now charge, and whether her complaint is still needed under TPKS.

### Victim compensation fund (PP 29/2025)

**Finding.** It exists, is for TPKS victims and is run by LPSK. It covers unpaid restitution and recovery funding. She, her family or an attorney applies in writing, and the rule sets a 30-day decision and payment period. ICJR says access comes only after the long restitution process and that there is no emergency route. No payout was confirmed. A low-confidence news report suggests little restitution is actually paid. Coverage of household sexual violence would follow from TPKS Pasal 4(2)(h), but that is inference. **Recommendation: do not add this to the FAQ.** It would raise hopes that nothing confirms.

**Grade:** SECONDARY.

**Sources:** [PP 29/2025](https://pasal.id/peraturan/pp/pp-no-29-tahun-2025); [ICJR](https://icjr.or.id/catatan-krusial-terkait-pp-29-2025-tentang-dana-bantuan-korban-tindak-pidana-kekerasan-seksual/); [Ombudsman](https://ombudsman.go.id/artikel/r/pwkinternal--menanti-realisasi-dana-bantuan-korban-tindak-pidana-kekerasan-seksual); [Journal Arta](https://journalarta.com/news/2026/08/08/dasco-sebut-komitmen-bantuan-untuk-korban-tpks-capai-rp200-miliar/).

**Lawyer's first check:** whether LPSK has paid anyone, and whether a wife qualifies.

### KHI Pasal 105, 116, 149, 156

**Finding.** The pack describes them correctly. Pasal 105: under 12 or not yet mumayyiz goes to the mother, a mumayyiz child chooses, the father pays. Pasal 116 lists divorce grounds, including cruelty or serious abuse, constant quarrels and breach of taklik talak. Pasal 149 applies when the marriage ends by talak, which is why SEMA 3/2018 matters for a wife who files. Pasal 156 adds the safety ground for moving custody, and the father pays according to ability, at least until 21. A journal's claim that custody ends if the mother remarries is not in the text read. KHI is a presidential instruction, not a statute.

**Grade:** SECONDARY. The text is marked unreviewed.

**Sources:** [KHI Pasal 105](https://pasal.id/peraturan/khi/kompilasi-hukum-islam/pasal-105), [116](https://pasal.id/peraturan/khi/kompilasi-hukum-islam/pasal-116), [149](https://pasal.id/peraturan/khi/kompilasi-hukum-islam/pasal-149), [156](https://pasal.id/peraturan/khi/kompilasi-hukum-islam/pasal-156); [PA Sengeti, Pasal 105](https://www.pa-sengeti.go.id/artikel/2341-tinjauan-analitis-pasal-105-kompilasi-hukum-islam-tentang-hak-hadhanah-dan-batasan-umur-mumayyiz-korik-agustian-s-ag-m-ag).

**Lawyer's first check:** whether Bekasi courts have a practice on custody when violence is alleged.

### How long a divorce claim takes

**Finding.** Hukumonline says up to 6 months at first instance. Actual figures for Bekasi: NOT FOUND. An appeal adds time. Cost: about Rp1.24 million is an estimate, and the court's own decision on fees for PA Bekasi was not found. She files at the religious court of where she lives.

**Grade:** SECONDARY.

**Source:** [Hukumonline guide](https://www.hukumonline.com/klinik/a/cara-dan-biaya-mengurus-perceraian-tanpa-pengacara-cl5021/).

**Lawyer's first check:** PA Bekasi's current fee decision and typical duration.

### Does BPJS cover a visum?

**Finding: sources conflict.** Perpres 59/2024 excludes care for victims of abuse and sexual violence that is already covered by another government scheme. KDRT is not named. One reading, from LPSK and DPR material seen only in a search summary, is that BPJS must pay if no other scheme does. Against that, BPJS branch statements in 2026 say not covered. A deputy chair of the MPR and an academic say BPJS no longer covers visum or KDRT services. Others say a visum is a forensic service and never automatically a benefit. No official ruling was found.

**Grade:** SECONDARY and conflicting. Official ruling: NOT FOUND.

**Sources:** [Perpres 59/2024](https://pasal.id/peraturan/perpres/perpres-no-59-tahun-2024); [RRI Mataram](https://rri.co.id/mataram/kesehatan/2510121/bpjs-kesehatan-tidak-tanggung-biaya-korban-dan-pelaku-perkelahian); [Radar Nganjuk](https://radarnganjuk.jawapos.com/amp/hukum-kriminal/2606220006/korban-pembacokan-di-nganjuk-tak-ditanggung-bpjs-biaya-perawatan-capai-rp95-juta); [Lestari Moerdijat](https://nasdemdprri.id/berita/perlindungan-korban-kekerasan-harus-menjadi-tanggung-jawab-bersama); [Wacana](https://wacana.org/zulfendri-dosen-fkm-usu-tanggapi-kebijakan-bpjs-bagi-perlindungan-kesehatan-korban-kekerasan/); [analysis blog](https://galihendradita.wordpress.com/2026/09/13/korban-tindak-pidana-ditanggung-jkn-analisis-perpres-59-2024/).

**Lawyer's first check:** ask BPJS Kesehatan Bekasi and the local UPTD PPA directly. This may not need a lawyer.

### Is Permen PPPA 4/2018 revoked?

**Finding.** Not shown as revoked. BPK lists it as in force, with nothing under "revoked by". The earlier "Pencabutan" marker refers to the older rules that it revoked. Permen 2/2022 cites it as live. Perpres 55/2024 is now a higher basis, and how far it replaces the 2018 rule was not resolved.

**Grade:** PRIMARY for status.

**Source:** [BPK record](https://peraturan.bpk.go.id/Details/240360/permen-pppa-no-4-tahun-2018).

**Lawyer's first check:** whether Perpres 55/2024 overrides any part of it. KemenPPPA's own legal site returned an access error.

## 5. Other answers: spot-check

**Answer 1.** Pasal 26 is confirmed, but it does not say the authority must be written. "A criminal case only starts if a police report is made" is incomplete. Pasal 16 and 19 start from police knowing or receiving a report, and only some offences need her complaint. The service standard sets response times on paper: high risk immediately, medium about 6 hours, low within 3x24 hours (p. 31). Outreach has its own: 1x24, 2x24 and 3x24 hours (p. 33). Practice: the Deputy Minister was asked about slow SAPA responses in June 2026. Grade: PRIMARY for statute and standard, SECONDARY for practice. Lawyer's first check: can police act on a third-party report of a non-complaint offence without her cooperation?

**Answer 2.** Pasal 10(c) is confirmed. The anonymous option remains SECONDARY, and the SAPA site was not read. Intake collects name, address and contact details (p. 30). No rule on contacting the husband was found in the pages read: most of pp. 16 to 47 and pp. 60 to 64, out of 93. One clue: if the service receives reports from both the victim and the suspect in one case, it puts the victim first and refers the suspect elsewhere (p. 28). That is not a rule about contact. The "we don't know" stays. Lawyer's first check: how she would be identified to him in each kind of case.

**Answer 5.** Holds. The 6-month living-apart rule on quarrel grounds, with an exception where household violence is found, is added. Proving that violence is the practical difficulty. Sources: [PTA Pekanbaru](https://www.pta-pekanbaru.go.id/62046/ingin-mengajukan-cerai-karena-sering-bertengkar-pahami-dasar-hukumnya-terlebih-dahulu-.html). The service standard confirms SKTM and other proofs of low income for the court's legal help desk (pp. 45 to 46). Grade: SECONDARY, except the standard. Lawyer's first check: the official SEMA 3/2023 text.

**Answer 6.** Holds. SEMA 3/2018 is confirmed through [Hukumonline](https://www.hukumonline.com/klinik/a/hak-istri-setelah-menggugat-cerai-suami-lt5e7315368865f). The exact wording of SEMA 2/2019, on court documents and payment, was not found. Non-Muslim families are not covered by this answer. Grade: SECONDARY. Lawyer's first check: how a violence allegation affects custody in practice.

**Answer 8.** Pasal 21 and 55 are confirmed. The service standard's evidence list (p. 47) includes ID, marriage certificate, visum or medical letter, photos and psychological reports. Grade: PRIMARY for those. Recordings: see section 4. TPKS Pasal 25 adds the judge's conviction but applies to TPKS cases. Lawyer's first check: section 4, recordings.

**Answer 9.** Statute and standard hold, but the visum sentence does not. Rule: Permen 2/2022 Pasal 9(2) says service costs are not charged to the beneficiary. The ethics section (p. 18) says staff may not ask for payment. P. 60 says the regional office must budget for the UPTD PPA and gives visum as an example cost line, marked as examples only. Practice: [Kompas, June 2026](https://nasional.kompas.com/read/2026/06/24/16244711/veronica-tan-jawab-layanan-sapa-129-yang-lamban-berakibat-korban-kekerasan?page=1) says it is budgeted but there are field problems. [Suara Sulsel, Aug 2026](https://sulsel.suara.com/read/2026/08/16/093604/korban-kekerasan-dipaksa-bayar-biaya-visum-zakat-diusulkan-jadi-solusi-dana-darurat) reports victims paying in several regions. [LPM Institut, Apr 2026](https://lpminstitut.com/2026/04/24/visum-tak-lagi-ditanggung-hambat-keadilan-korban/) (campus press) ties this to a 50% national budget cut. [Unair](https://unair.ac.id/guru-besar-fisip-unair-tanggapi-penghentian-pembiayaan-visum-bagi-korban-kekerasan-seksual/) comments on the same issue. Bekasi: NOT FOUND. Reported amounts run from Rp150,000 to around Rp1 million. Lawyer's first check: not a lawyer item first. A call to Bekasi's UPTD PPA would answer most of it.

**Answer 10.** Holds and is sharpened. TPKS Pasal 23 and KUHAP Pasal 82 are confirmed. KUHAP Pasal 23 gives her proof of the report and a route to the investigator's superior after 14 days without a response. LBH APIK's 2025 complaint about having no way to object predates this. Whether it works in practice is unknown. The standard's mediation section (pp. 38 to 42) says the decision is hers, that mediation is for certain cases only, and that an agreement does not free the other person from liability. Grade: SECONDARY for KUHAP and TPKS, PRIMARY for the standard. Lawyer's first check: how Pasal 23 works when police refuse to log a report at all.

## 6. Article map in AI_CONTRACTS.md

**Result: confirmed.** Pasal 6, 7, 8, 9 and 44, 45, 46, 49 are the right articles. Grade: PRIMARY, [UU 23/2004 PDF](https://peraturan.bpk.go.id/Download/30306/UU%20Nomor%2023%20Tahun%202004.pdf). BPK shows the law as in force, with no amendments listed. No edit was made to `AI_CONTRACTS.md`.

Details the map does not show:

- Pasal 46 covers only Pasal 8(a), forced relations with someone in the household. Pasal 8(b), forcing someone into sex with another person, maps to Pasal 47. Pasal 48 is the aggravated form.
- Pasal 44 and 45 each include a 4-month complaint version (44(4), 45(2)).
- Pasal 46 is a complaint offence only between spouses (Pasal 53).
- Pasal 49 covers both 9(1) and 9(2).
- The fine amounts printed in Pasal 44 to 49 appear to have been changed by UU 1/2026 (see section 4). The prison terms were not.

## Follow-on points in other files (not edited)

- `SAFETY.md` line 46: "A police case starts only if a police report is made." Same issue as answer 1.
- `SAFETY.md` line 48: "No published response time was found." The service standard has one on paper.
- `SAFETY.md` line 50: "not to her husband". Same issue as answer 2.
- `AI_CONTRACTS.md` line 91, and the matching text in `PRODUCT.md` and `FIXTURES.md`: the caveat list covers answers 4, 7 and 11 only.
- `PRODUCT.md` line 173 and `BUILD_PLAN.md` line 10 still show this work as open or pending a lawyer.
- `SAPA_FORM.md`: check how it handles a safe way to reach her, given the outreach rule. Only its contact fields were searched.
- Our research notes: the statements on 44(1), detention and response times are out of date.
- The app answers in Indonesian. That translation has not been reviewed. Any approved text should be translated with care, especially "appear", "may" and "we don't know".

## Sources that failed to load

| Source | Result |
|---|---|
| peraturan.go.id PDFs of UU 1/2026 and UU 20/2025; BPK PDF of UU 20/2025 | Over the 10 MB limit |
| BPK reader page for UU 20/2025 | Loads only a viewer |
| jdih.kemenkoinfra.go.id PDF of UU 20/2025 | 404 |
| sisdivkum.polri.go.id PDF of UU 1/2026 | Certificate error |
| lpsk.go.id article on BPJS | Certificate error |
| marinews.mahkamahagung.go.id articles, including two of the FAQ's own links for answer 6 | Tested article returned 403. Others not read. |
| datahukum.com | 403 |
| jdih.kemenpppa.go.id and the kemenpppa.go.id release on Perpres 55/2024 | 403 |
| rifka-annisa.org article on the 6-month rule | 404 |

Not read at all: the official text of SEMA 1/2026, SEMA 3/2018 and SEMA 3/2023, and the SAPA 129 website. Pages 35, 43, 48 to 59 and 65 to 93 of Permen PPPA 2/2022 were not read. Its first 15 pages were read only in part.

No web page tried to give the AI instructions.

## Team checklist

Tick when the team has decided. For each answer: approve the proposed text, keep the original, or write something else.

General:

- [ ] Read the warning at the top of `LEGAL_FAQ.md`
- [ ] Confirm the AI receives approved text only, not the research blocks
- [ ] Decide whether the caveat list should go beyond answers 4, 7 and 11
- [ ] Decide on the follow-on points in `SAFETY.md`
- [ ] Keep calling the FAQ "not lawyer-checked" in all app copy
- [ ] Compare the key KUHAP and KUHP articles against an official PDF if possible

Answer by answer:

- [ ] **Answer 1:** someone may come or police may be involved. Decide on proposed text.
- [ ] **Answer 2 (WARNING):** "not to your husband". Decide on proposed text.
- [ ] **Answer 3 (WARNING):** "Yes." Choose the original reword or the fuller update.
- [ ] **Answer 4:** restorative justice and detention. Decide on proposed text.
- [ ] **Answer 5:** 6-month living-apart rule, softer cost figure. Decide on proposed text.
- [ ] **Answer 6:** small sharpening. Decide on proposed text.
- [ ] **Answer 7:** court's "proper reason" exception, her own application, practice. Decide on proposed text.
- [ ] **Answer 8:** recordings softened. Decide on proposed text.
- [ ] **Answer 9 (WARNING):** "usually free". Decide on proposed text.
- [ ] **Answer 10:** no-pressure rule, 14-day route, mediation. Decide on proposed text.
- [ ] **Answer 11 (highest priority):** 6-month limit. Decide on proposed text.
- [ ] **Answer 12 (WARNING):** 14-day limit. Decide to keep or drop, then decide on proposed text.

Phone calls, not lawyer items:

- [ ] Does Kota Bekasi and Kabupaten Bekasi each have a working UPTD PPA and a shelter?
- [ ] Can children stay with a mother in the shelter?
- [ ] Would she be charged for a visum in Bekasi, and does BPJS pay?
- [ ] When would the service contact a husband, and how would it reach her safely?

If a lawyer becomes available, start with these, in this order:

- [ ] Does KUHP Pasal 29 (6 months) apply to PKDRT complaint offences, and how is it counted?
- [ ] Can her name be kept from him in any court route?
- [ ] Is Pasal 44(1) eligible for restorative justice, and how does Pasal 204(7) apply to spouses?
- [ ] Can she safely record a conversation she is part of?
- [ ] Which law governs marital rape?
