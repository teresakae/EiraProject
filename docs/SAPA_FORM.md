# SAPA 129 report form

Fields and dropdown values for the report draft. Indonesian strings are unchanged. The values were mirrored from the live form at laporsapa129.kemenpppa.go.id/lapor in Oct 2026.

Status: DECIDED as the source for the report fields. Re-verify against the live form (see the end of this file).

## Rules from the source file

- Every report from this app is "tidak darurat" (not urgent). "darurat" is not a field here.
- The phone number is optional on SAPA's own form and in this app (owner confirmed, 7 Nov 2026; C23).
- A field with no source in her words stays empty. She can fill it herself.
- Text fields accept at most 5000 characters.

## Fields

| Field | Type | Required in this app | Meaning |
|---|---|---|---|
| `is_victim` | dropdown | yes | Did it happen to the user, or did she see or hear it happen to someone else? |
| `level_concern` | dropdown | yes | How worried the user is. |
| `relationship_with_victim` | dropdown | yes | The perpetrator's relationship to the victim. |
| `incident_time` | dropdown | yes | Time of day it happened. |
| `location` | dropdown | yes | Type of place it happened. |
| `province_city` | text | yes | City and province, for example "Kota Bandung, Jawa Barat" or "Kota Jakarta Selatan, DKI Jakarta". |
| `description` | text | yes | What happened, in Indonesian, in order, using only what the user said. |
| `korban_fullname` | text | no | The victim's name (optional). |
| `korban_gender` | dropdown | yes | The victim's gender. Empty unless the user said it (girl, boy, sister, son and so on). Never assume it from the story. |
| `korban_age` | whole number, 1 to 100 | yes | The victim's age in years. |
| `korban_disabilities` | yes or no | yes | Does the victim have a disability? |
| `korban_disabilities_type` | dropdown | only if `korban_disabilities` is yes | Type of disability, only if she has one. |
| `korban_contact_number` | text, digits only | no | The victim's phone number (optional). |
| `korban_trusted_person` | text, digits only | no | Phone number of an adult the victim trusts (optional). |
| `reporter_fullname` | text | yes, unless `anonymous` is yes | The reporter's name. |
| `anonymous` | yes or no | no | Does the reporter want to stay anonymous? |
| `contact_number` | text, digits only | no | The reporter's phone number. |

## Required fields: the rule

A report is ready when none of these is empty:

1. `is_victim`, `level_concern`, `relationship_with_victim`, `incident_time`, `location`
2. `province_city`, `description`, `korban_gender`, `korban_age`, `korban_disabilities`
3. `korban_disabilities_type`, but only when `korban_disabilities` is yes
4. `reporter_fullname`, but only when `anonymous` is not yes

"Empty" means null, missing, or an empty string. The app uses this list to flag empty required fields. It is information for her, not a push to complete the report.

## Dropdown values

**`is_victim`**

| Value |
|---|
| `saya_sendiri` |
| `orang_lain` |

**`level_concern`**

| Value |
|---|
| `sedikit_khawatir` |
| `khawatir` |
| `sangat_khawatir` |

**`relationship_with_victim`**

| Value |
|---|
| Orang Tidak Dikenal |
| Diri Sendiri |
| Kenalan Baru |
| Pengurus Rumah Tangga |
| Guru |
| Lainnya |
| Petugas Layanan |
| Petugas Sekolah |
| Teman |
| Suami/Istri |
| Tetangga/ Teman keluarga |
| Kerabat |
| Ayah Kandung |
| Ibu Kandung |
| Pengasuh Utama |
| Anak |
| Pacar |
| Rekan Kerja |
| Atasan / Majikan |

**`incident_time`**

| Value |
|---|
| Pagi |
| Siang |
| Sore |
| Malam |
| Tidak Diketahui |

**`location`**

| Value |
|---|
| Rumah Tangga |
| Tempat Kerja |
| Sekolah/Kampus |
| Sarana Umum |
| Situasi Darurat/Tempat Bencana |
| Daring/Elektronik |

**`korban_gender`**

| Value |
|---|
| laki-laki |
| perempuan |

**`korban_disabilities_type`**

| Value |
|---|
| Mengalami kesulitan melihat, meskipun memakai kacamata |
| Mengalami kesulitan mendengar, meskipun menggunakan alat bantu dengar |
| Mengalami kesulitan berkomunikasi, misalnya memahami atau dimengerti |
| Mengalami kesulitan mengingat atau berkonsentrasi |
| Mengalami kesulitan dengan perawatan diri seperti membersihkan seluruh tubuh atau berpakaian |
| Mengalami kesulitan berjalan atau menaiki tangga |

## Not part of the form

Do not add `category` or `intensity` fields. They are not SAPA fields and are not part of the report.

## Re-verify against the live form, and the mock

The values were copied in Oct 2026. Before relying on them, read the live form to map its fields. Only read it. Never submit it. It is a real government intake. Do not enter test data into it, even partially.

UNVERIFIED about the live form: whether it has a captcha, several steps, or a login; whether the page sends anything before she presses send (for example autosave).

The mock form is a local copy bundled in the app, built from the field list and dropdown values in this file. It shows what it received and sends nothing anywhere. Test the fill against the mock only.
