# BSC-500 Attendance Application

This is an attendance and points tracker for the Business Student Council (BSC) at Texas A&M University, built for members to check into events, track category progress, and submit attendance appeals, and for officers to manage events, members, and school-year point exports.

## Table of Contents

- [Features](#features)
- [Requirements & Dependencies](#requirements--dependencies)
  - [Internal Requirements](#internal-requirements)
  - [External Dependencies](#external-dependencies)
  - [Third-Party & AI Libraries](#third-party--ai-libraries)
- [Environment Variables & Required Files](#environment-variables--required-files)
- [Getting Started (Installation & Setup)](#getting-started-installation--setup)
- [Running Tests & Linters Locally](#running-tests--linters-locally)
- [CI/CD Pipeline & Deployment](#cicd-pipeline--deployment)
- [Configuration Items List](#configuration-items-list)
- [OAuth & Environment Configuration Notice](#oauth--environment-configuration-notice)
- [Member Quick Start & Check-in Guide](#member-quick-start--check-in-guide)
- [Admin Role Management & Dashboard Guide](#admin-role-management--dashboard-guide)
- [Known Limitations, Support & Next Steps](#known-limitations-support--next-steps)
- [Documentation](#documentation)
- [Contact, Credits & AI Use](#contact-credits--ai-use)

---

## Features

- **TAMU Google OAuth 2.0 Sign-In:** Restricts login to `@tamu.edu` Google Workspace accounts and enforces profile completion (Full Name, 9-digit UIN, Class Year).
- **Event Self Check-In:** Members check into active events within configurable opening/closing windows with optional officer check-in codes.
- **Semester & Category Progress Tracking:** Live point totals and progress bars grouped by event category for the active semester.
- **Attendance Appeals with Proof Upload:** Members submit appeals with optional PDF, JPG, or PNG attachments (via Active Storage) for administrator approval or denial.
- **Admin Dashboard & Roster Management:** Officers manage events, categories, semesters, semester requirements, member roles (Promote/Revoke Admin), member archiving, manual point adjustments, and school-year CSV exports.
- **In-App & External Documentation:** Built-in `/support` help guides for members and admins, plus external operational runbooks (`RESTART.md`).

---

## Requirements & Dependencies

### Internal Requirements

| Component | Version / Details |
| :--- | :--- |
| **Ruby** | `3.4.6` (see `.ruby-version` and `Dockerfile`) |
| **Rails** | `8.1.4` |
| **PostgreSQL** | `16+` (`pg` gem `1.6.3`) |
| **Asset Pipeline** | `importmap-rails` & `propshaft` (no Node.js/Yarn build step required) |

### External Dependencies

| Dependency | Purpose | Link |
| :--- | :--- | :--- |
| **Docker Desktop** | Containerized local development environment | https://www.docker.com/products/docker-desktop |
| **Heroku** | Production hosting (`bsc-500-prod`) and managed PostgreSQL | https://www.heroku.com/ |
| **Git & GitHub** | Version control and GitHub Actions CI workflows | https://github.com/ |
| **Google Cloud Console** | Google OAuth 2.0 client credentials (`@tamu.edu` auth) | https://console.cloud.google.com/apis/credentials |

### Third-Party & AI Libraries

- **Core Ruby Gems (`Gemfile` / `Gemfile.lock`):** `omniauth-google-oauth2` & `omniauth-rails_csrf_protection` (Google OAuth2), `pg` (PostgreSQL adapter), `puma` (web server), `bootsnap` (boot caching), `rspec-rails` & `shoulda-matchers` (test suite), `rubocop` & `rubocop-rails-omakase` (code linting), `brakeman` (security static analysis), `importmap-rails` (JavaScript dependency management).
- **AI Libraries:** This application does **not** use any AI or machine learning libraries, models, or external AI APIs at runtime.

---

## Environment Variables & Required Files

Secrets are never committed to Git. Configure the following environment variables in a local `.env` file (ignored by `.gitignore`) for development and in **Heroku Config Vars** for production:

| Variable | Description |
| :--- | :--- |
| `GOOGLE_CLIENT_ID` | OAuth 2.0 Web Client ID from Google Cloud Console |
| `GOOGLE_CLIENT_SECRET` | OAuth 2.0 Web Client Secret from Google Cloud Console |
| `DATABASE_URL` | PostgreSQL connection string (automatically managed by Heroku Postgres in production) |
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` in production (never commit `config/master.key`) |

Example local `.env` structure (do not commit real values):

```env
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-client-secret
```

---

## Getting Started (Installation & Setup)

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/](https://github.com/)<customer-github-username>/BSC-500.git
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
   Open `http://localhost:3000` in your browser. For containerized Docker setup and recovery steps, see [`RESTART.md`](RESTART.md).

---

## Running Tests & Linters Locally

Run static analysis, security scans, and the test suite before pushing changes:

```bash
# Run RuboCop for code style and linting
bundle exec rubocop

# Run Brakeman static security analysis
bin/brakeman --no-pager

# Audit pinned JavaScript dependencies
bin/importmap audit

# Run RSpec test suite (ensure PostgreSQL service is running)
bundle exec rspec
```

---

## CI/CD Pipeline & Deployment

This project uses **GitHub Actions** for automated static security and code-quality checks, paired with **Heroku** (`bsc-500-prod`) for production hosting.

```text
[ Push / PR to main ] ──> [ GitHub Actions CI: Brakeman + Importmap Audit + RuboCop ] ──> [ Deploy main to Heroku (bsc-500-prod) ]
```

### Continuous Integration (CI)
On every push or pull request to `main`, `.github/workflows/ci.yml` automatically runs three verification jobs:
- **`scan_ruby` (`bin/brakeman --no-pager`):** Static security analysis for common Rails vulnerabilities.
- **`scan_js` (`bin/importmap audit`):** Security vulnerability scan for pinned JavaScript dependencies.
- **`lint` (`bundle exec rubocop`):** Code style linting and formatting validation.

### Production Deployment & Change-Control Process
- **Production App:** `bsc-500-prod` (`https://bsc-500-prod-4351c3d46733.herokuapp.com`), connected directly to the customer-owned GitHub repository (`main` branch).
- **Change-Control Workflow:** All future changes should be committed or merged via Pull Request into `main` on the customer repository. Once GitHub Actions `CI` passes with all green checks, deploy the verified `main` branch to `bsc-500-prod` from the Heroku **Deploy** tab (or via Automatic Deploys when CI passes).

---

## Configuration Items List

| Item | Current Value / Details | Evidence Location |
| :--- | :--- | :--- |
| **Deployed code** | Customer-owned GitHub `main` branch (`bsc-500-prod` production deployment) | Customer GitHub commit history & Heroku **Activity** tab |
| **Runtime / framework** | Ruby `3.4.6` with Rails `8.1.4` | `Dockerfile` (`ARG RUBY_VERSION=3.4.6`), `.ruby-version`, and `Gemfile.lock` |
| **Dependencies** | Locked Ruby gems (`pg`, `omniauth-google-oauth2`) and Importmap JS pins | `Gemfile.lock` and `config/importmap.rb` |
| **Database & hosting** | PostgreSQL (`bsc_500_development` locally; **Heroku Postgres** via `DATABASE_URL` in production) | `config/database.yml` and Heroku **Resources** tab |
| **Authentication & secrets** | Google OAuth 2.0 (`@tamu.edu` domain restriction); owner **Logan Jaure** | Heroku **Config Vars** (`GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `RAILS_MASTER_KEY`) and Google Cloud Console |

---

## OAuth & Environment Configuration Notice

- **Application & Infrastructure Owner:** **Logan Jaure** (President, Business Student Council) — sole owner of the GitHub repository, Heroku production app (`bsc-500-prod`), and Google Cloud OAuth 2.0 project.
- **Production Environment Variables:** Managed exclusively in Heroku **Config Vars** (`DATABASE_URL`, `RAILS_MASTER_KEY`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`). No `.env` files or secrets are committed to Git history.
- **Google OAuth Callback URL:** `https://bsc-500-prod-4351c3d46733.herokuapp.com/users/auth/google_oauth2/callback` (configured in Google Cloud Console under **APIs & Services → Credentials**).
- **Local & Docker Setup:** Uses PostgreSQL (`pg` gem) and environment variables injected at runtime in accordance with 12-factor app practices. See [`RESTART.md`](RESTART.md) for step-by-step setup and recovery procedures.

---

## Member Quick Start & Check-in Guide

### Sign in and complete your profile

1. Open the BSC Attendance Portal (`https://bsc-500-prod-4351c3d46733.herokuapp.com`) and select **Sign in with Google**.
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

By default, check-in opens **15 minutes before** the scheduled event start and closes **1 hour (60 minutes) after** it (unless customized by an administrator when creating the event). You can check in only once per event; trying again will not award duplicate points.

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

## Known Limitations, Support & Next Steps

### Known behavior and limitations

- **Check-in window:** By default, check-in is available from **15 minutes before** until **1 hour (60 minutes) after** an event’s scheduled start (unless custom window minutes are configured on the event).
- **Authentication scope:** Only Google accounts with an `@tamu.edu` email address can sign in. A member whose access has been archived cannot sign in, even though their records are retained.
- **Database backups:** Automated backups depend on the active Heroku Postgres plan; administrators should export CSV point summaries and capture manual database backups prior to semester rollovers.

### Problem reporting and end of course support

- **End of Course Support:** CSCE 431 student development team support concludes upon final project turnover on **November 23, 2026**, at which point all student access to GitHub, Heroku, and Google Cloud is revoked.
- **How to Report Problems:** Future bugs, feature requests, and semester maintenance tasks should be logged under the **Issues** tab of the customer-owned GitHub repository.
- **Operational Recovery:** For routine restarts, environment variable updates, or database recovery steps, follow [`RESTART.md`](RESTART.md) in the repository root.

### Recommended next steps

- Verify Google OAuth settings and deployment details in the environment where the application will be used.
- Test the main workflows before a new term: TAMU sign-in and profile completion, event check-in and optional codes, role changes and archive safeguards, points exports, and appeal approval and denial.

---

## Documentation

- **In-App Help Guide:** `https://bsc-500-prod-4351c3d46733.herokuapp.com/support`
- **Setup & Operational Recovery Runbook:** [`RESTART.md`](RESTART.md)
- **Ruby on Rails Guides:** https://guides.rubyonrails.org/
- **OmniAuth Google OAuth2:** https://github.com/zquestz/omniauth-google-oauth2
- **Heroku Dev Center (Config Vars & Postgres):** https://devcenter.heroku.com/

---

## Contact, Credits & AI Use

- **Customer / Product Owner:** Logan Jaure — President, Business Student Council (`loganjaure@tamu.edu`)
- **Development Team (CSCE 431 — Fall 2026):**
  - Sohni Ballard — Product Owner & Developer
  - Ruth Jasadiredja — Scrum Master & Developer
  - Ethan Ford — Developer
  - Qayyum Alli — Developer
  - Cemal Duman — Developer
- **Issue Tracking:** Submit bug reports or enhancement requests via the **Issues** tab on the customer's GitHub repository.
- **AI Use Disclosure:** Generative AI assistants (Claude / Gemini) were used during development and turnover preparation to assist with documentation structuring, README completeness checks, and debugging workflows; all code, configurations, and documentation were reviewed and verified by the development team.