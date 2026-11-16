# BSC-500 Attendance Application

This is an attendance tracker for the Business Student Council's members and officers.

## Table of Contents

- [Getting Started](#getting-started)
  * [Prerequisites](#prerequisites)
  * [Installation](#installation)
- [Running Tests Locally](#running-tests-locally)
- [CI/CD Pipeline & Deployment](#cicd-pipeline--deployment)
- [Configuration Items List](#configuration-items-list)
- [OAuth & Environment Configuration Notice](#oauth--environment-configuration-notice)
- [Member Quick Start & Check-in Guide](#member-quick-start--check-in-guide)
  * [Sign in and complete your profile](#sign-in-and-complete-your-profile)
  * [Find events and check in](#find-events-and-check-in)
  * [View your points and category progress](#view-your-points-and-category-progress)
  * [Update your profile or submit an appeal](#update-your-profile-or-submit-an-appeal)
- [Admin Role Management & Dashboard Guide](#admin-role-management--dashboard-guide)
  * [Open the admin area](#open-the-admin-area)
  * [Review members and manage roles](#review-members-and-manage-roles)
  * [Archive a member](#archive-a-member)
  * [Review attendance appeals](#review-attendance-appeals)
  * [Export member points](#export-member-points)
  * [Manage events, categories, semesters, and requirements](#manage-events-categories-semesters-and-requirements)
- [Final Known Issues and Next Steps](#final-known-issues-and-next-steps)
  * [Known behavior and limitations](#known-behavior-and-limitations)
  * [Recommended next steps](#recommended-next-steps)

---

## Getting Started

### Prerequisites

Make sure you have the following installed on your local machine:

* **Ruby 3.4.6** (check `.ruby-version` or `Dockerfile`)
* **Rails 8.0**
* **Bundler** (`gem install bundler`)
* **PostgreSQL**

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/BSC-500.git
   cd BSC-500
   ```

2. **Install dependencies:**
   ```bash
   bundle install
   ```

3. **Set up the database:**
   ```bash
   bin/rails db:create db:migrate db:seed
   ```

4. **Start the local development server:**
   ```bash
   bin/rails server
   ```

---

## Running Tests Locally

Run static analysis and test suites before pushing code or creating a pull request:

```bash
# Run RuboCop for code style and linting
bundle exec rubocop

# Run RSpec test suite
bundle exec rspec
```

---

## CI/CD Pipeline & Deployment

This project utilizes **GitHub Actions** for continuous integration and automated deployments to **Heroku**.

```
[ Push / PR ] ──> [ GitHub Actions ] ──> [ RuboCop & RSpec ] ──> [ Auto-Deploy to Heroku Staging ]
```

### Continuous Integration (CI)
On every push or pull request to the main branch, GitHub Actions automatically runs the following verification steps:
* **RuboCop:** Code style linting and formatting validation.
* **RSpec:** Automated test suite execution to prevent regressions.

### Continuous Deployment (CD)
* **Heroku Staging App:** Upon successful completion of all CI checks (RuboCop and RSpec), GitHub Actions automatically triggers an automated push to deploy the latest build to the Heroku Staging environment.

---

## Configuration Items List

| Item | What to Record | Evidence Location |
| :--- | :--- | :--- |
| **Deployed code** | Git Commit `16f2a89` (GitHub) / `16f2a891` (Heroku Release) | GitHub repository commit history / Heroku deployment pipeline |
| **Runtime/framework** | Ruby 3.4.6 with Rails 8.0 | `Dockerfile` (`ARG RUBY_VERSION=3.4.6`), `.ruby-version`, and `Gemfile` |
| **Dependencies** | Locked Gem versions (`pg`), multi-stage Docker build (`ruby:3.4.6-slim`) | `Gemfile.lock` and `Dockerfile` |
| **Database and deployment environment** | PostgreSQL (`bsc_500_development` locally, Heroku Postgres via `DATABASE_URL` in production) | `config/database.yml` and Heroku Add-ons dashboard |
| **Supporting instructions** | OAuth configurations, owner details (Qayyum Alli), and deployment guidance | `README.md` and Heroku Config Vars (`OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`) |

---

## OAuth & Environment Configuration Notice
- **OAuth Owner:** Qayyum Alli
- **Production Deployment:** Deployed on Heroku with production database connections handled automatically via `DATABASE_URL`. OAuth credentials (Client ID and Secret) are stored securely in Heroku Config Vars.
- **Local & Docker Setup:** Uses PostgreSQL adapter (`pg` gem). Secrets are injected dynamically via environment variables in accordance with 12-factor app practices and are never hardcoded.

---

## Member Quick Start & Check-in Guide

### Sign in and complete your profile

1. Open the BSC Attendance Portal and select **Sign in with Google**.
2. Sign in with your official TAMU Google account ending in `@tamu.edu`. Personal Gmail and other email domains are not accepted.
3. Complete your member profile with your full name, nine-digit UIN, and class year, then save it. You may be redirected to your profile if required information is missing.

If sign-in is denied, check that you selected your TAMU account. If you cannot access the portal with that account, contact a BSC administrator.

### Find events and check in

1. Open **Check-In** from the navigation. Events are listed under **Upcoming Events** or **Past Events**, with their date, time, and point value.
2. Check the event’s status:
   - **Open** means check-in is available.
   - **Upcoming** means the check-in window has not opened.
   - **Checked in** means your attendance has already been recorded.
   - **Absent** means the event’s scheduled start time has passed and you have not checked in. An event may still be open for check-in during the allowed window.
3. Select an open event and press **Click to check-in**.
4. If the event asks for a check-in code, get the code from a BSC officer and enter it before submitting.
5. Look for the confirmation message and checkmark to confirm that your attendance was recorded.

Check-in opens **15 minutes before** the scheduled event start and closes **3 hours after** it. You can check in only once per event; trying again will not award duplicate points.

### View your points and category progress

Your home page shows your earned points by category for the current semester. Checking in adds the event’s point value to your attendance record. Category requirements show whether you have met the semester’s requirement, are still in progress, or have no requirement set.

If the page says **No active semester** or **No categories have been set up yet**, contact a BSC officer. Administrators select the current semester by creating it; the most recently created semester is treated as current.

### Update your profile or submit an appeal

- Open **User Profile** to review your information or select **Edit profile** to update it.
- Open **Appeals** to submit an attendance appeal for a past or upcoming event, explain your reason, and optionally attach a PDF, JPG, or PNG smaller than 10 MB. You can review your appeal’s status and history on that page.
- A pending appeal requires administrator review. If approved, attendance is recorded and the event’s points are awarded once. If denied, attendance and points are unchanged.

---

## Admin Role Management & Dashboard Guide

### Open the admin area

Sign in with an account that has administrator access. Admins see **Admin** and **Events** in the navigation. The **Admin** page includes pending appeals, a school-year points export, and the member roster.

### Review members and manage roles

1. Use **Active Members** and **Archived Members** to switch between rosters.
2. Select **View Details** to review a member’s profile, total points, attendance points, administrator adjustment, and event history.
3. Select **Edit Member** to update profile information or correct total points. A total-points correction changes the administrator adjustment; it does not erase attendance records. Future check-ins continue to add points. Category progress is based on attendance, not the administrator adjustment.
4. Select **Make Admin** or **Revoke Admin** to change a member’s role, then confirm the prompt.

Role changes affect access to the admin area. The last active administrator cannot be revoked, and an administrator cannot revoke their own access.

### Archive a member

1. Select **Delete Member** on the member’s details.
2. Review the confirmation page and check the confirmation box before selecting **Archive Member**.

Archiving removes the member from the active roster but retains their profile, points, attendance, and appeals. It disables access to the application, including future sign-ins. It does not delete or disable the member’s Google account. Administrators cannot archive their own account or the last active administrator.

### Review attendance appeals

Open **Pending Attendance Appeals** or select **View All Appeals**. Choose an appeal to review the member’s reason, event, and any attached proof. Select **Approve** or **Deny**. Approval records attendance and awards the event’s points once; denial leaves attendance and points unchanged. An appeal cannot be reviewed again after it has been decided.

### Export member points

Under **Export Member Points**, select a school year and choose **Export CSV**. The export covers the school year from **August 1 through July 31**.

### Manage events, categories, semesters, and requirements

Use **Events** to create or edit events. Each event needs a name, date and time, description, point value, category, and semester. A check-in code is optional; when one is set, members must enter it to check in.

Administrators can also manage categories, create semesters, and set category requirements for a semester. Create the semester before assigning it to events or configuring its requirements. Leave a category requirement blank when no requirement should apply. A category cannot be deleted while it is used by events or semester requirements. Because the most recently created semester is treated as current for member progress, create semesters in the intended order.

---

## Final Known Issues and Next Steps

### Known behavior and limitations

- Administrator point adjustments change a member’s total points but do not change attendance-based category progress.
- Check-in is available only from 15 minutes before until 3 hours after an event’s scheduled start.
- Only Google accounts with an `@tamu.edu` email address can sign in. A member whose access has been archived cannot sign in, even though their records are retained.

### Recommended next steps

- Verify Google OAuth settings and deployment details in the environment where the application will be used.
- Test the main workflows before a new term: TAMU sign-in and profile completion, event check-in and optional codes, role changes and archive safeguards, points exports, and appeal approval and denial.
