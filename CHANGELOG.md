# Changelog

All notable changes to the **BSC Attendance Application** are documented in this file.

---

## [1.2.0] - 2026-11-02 (SCRUM Sprint 3)

### Added
- **Optional Event Check-In Codes (`US-17`, `US-18` / `SCRUM-33`, `SCRUM-32`):**
  - Admins can configure, update, or remove check-in codes for individual events (`Admin::EventsController`)[cite: 1].
  - Members must submit the correct code to successfully check in when configured for an event (`CheckInsController`)[cite: 1].
  - Timing-attack-resistant SHA-256 comparison using `ActiveSupport::SecurityUtils.secure_compare`.
- **Attendance Appeals System (`US-11`, `US-14` / `SCRUM-3`, `SCRUM-5`):**
  - Members can submit attendance appeals for past or upcoming events, complete with detailed notes and file attachments (`AppealsController`)[cite: 1].
  - Admins can review, approve (awarding attendance points once), or deny pending appeals (`Admin::AppealsController`)[cite: 1].
- **Point Records Tracking (`US-25` / `SCRUM-34`):**
  - Detailed breakdown of member attendance history, category requirements, total points earned, and admin point adjustments[cite: 1].
- **General User Support Portal (`US-23` / `SCRUM-30`):**
  - Added user support pages and help instructions accessible within the portal[cite: 1].

### Changed
- **Event Dashboard Organization (`US-12` / `SCRUM-8`):**
  - Categorized events into **Upcoming** (ordered earliest first) and **Past** (ordered most recent first) across both member and admin event views[cite: 1].
  - Refactored event status badge logic to clearly distinguish between *Upcoming*, *Open*, *Checked in*, and *Absent* statuses[cite: 1].
- **UI & Layout Refresh (`US-19` / `SCRUM-29`):**
  - Standardized application-wide navigation bar, member detail views, status indicators, and modal layouts[cite: 1].

### Deployment & Infrastructure
- **Web Deployment (`US-28` / `SCRUM-28`):**
  - Deployed production release on Heroku Staging/Production environments with continuous integration checks[cite: 1].
