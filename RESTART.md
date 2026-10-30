# System Restart & Recovery Guide

**Application:** BSC Event Tracker

**Production App Name:** `bsc-500-prod-4351c3d46733`

**Production URL:** `https://bsc-500-prod-4351c3d46733.herokuapp.com/`

**Stack:** Ruby on Rails | Heroku | PostgreSQL | GitHub

**Audience:** System Administrators / DevOps Leads

---

## Overview

This document provides step-by-step procedures for restarting and recovering the BSC Event Tracker application during outages, deployment issues, or system unresponsiveness. Because this guide is hosted directly in the GitHub repository, it remains accessible even when the primary Heroku web application is offline.

---

## Emergency Protocol: Quick Heroku Restart

If the web application becomes unresponsive, returns `500` / `502` / `503` errors, or fails to complete Google OAuth handshakes, perform a restart via the Heroku CLI or Dashboard.

### Method 1: Heroku CLI (Recommended)

1. Open your terminal and log into the Heroku CLI with authorized credentials:
   ```bash
   heroku login
   ```

2. Restart all dynos for the production app:
   ```bash
   heroku restart --app bsc-500-prod-4351c3d46733
   ```

3. Tail the live operational logs to monitor the reboot process:
   ```bash
   heroku logs --tail --app bsc-500-prod-4351c3d46733
   ```

### Method 2: Heroku Web Dashboard

1. Log in to the [Heroku Dashboard](https://dashboard.heroku.com/).
2. Select the **bsc-500-prod-4351c3d46733** application.
3. In the top-right corner, click **More** > **Restart all dynos**.
4. Confirm the restart action.
5. Monitor runtime events by clicking **More** > **View logs**.

---

## Detailed Recovery & Troubleshooting Scenarios

### Scenario A: Database Connection Pool Exhausted / Database Unresponsive

If application logs indicate `PG::ConnectionBad` or database connection timeouts:

1. Restart the Postgres database connections by restarting application dynos:
   ```bash
   heroku restart --app bsc-500-prod-4351c3d46733
   ```

2. If the issue persists, check database status and active connections:
   ```bash
   heroku pg:info --app bsc-500-prod-4351c3d46733
   heroku pg:ps --app bsc-00-prod-4351c3d46733
   ```

3. If necessary, terminate stuck database connections:
   ```bash
   heroku pg:killall --app bsc-500-prod-4351c3d46733
   ```

### Scenario B: Pending Rails Database Migrations

If a deployment introduced schema updates that were not automatically run:

1. Enable maintenance mode:
   ```bash
   heroku maintenance:on --app bsc-500-prod-4351c3d46733
   ```

2. Run pending database migrations:
   ```bash
   heroku run rails db:migrate --app bsc-500-prod-4351c3d46733
   ```

3. Restart dynos and turn off maintenance mode:
   ```bash
   heroku restart --app bsc-500-prod-4351c3d46733
   heroku maintenance:off --app bsc-500-prod-4351c3d46733
   ```

### Scenario C: Rolling Back a Bad Deployment

If a newly deployed GitHub commit breaks core application features (e.g., Google OAuth or check-in verification):

1. View recent releases:
   ```bash
   heroku releases --app bsc-500-prod-4351c3d46733
   ```

2. Roll back to the previous stable release (e.g., `v24`):
   ```bash
   heroku releases:rollback v24 --app bsc-500-prod-4351c3d46733
   ```

3. Revert or patch the problematic commit on GitHub before pushing to `main` again.

---

## Post-Restart Verification Checklist

Once the restart sequence completes, perform the following verification steps:

- [ ] **Application Status:** Visit [https://bsc-500-prod-4351c3d46733.herokuapp.com/](https://bsc-500-prod-4351c3d46733.herokuapp.com/) and ensure the home page loads cleanly.
- [ ] **Google OAuth Test:** Attempt to log in with an authorized `@tamu.edu` account to confirm OAuth routing is active.
- [ ] **Clock & Event Check-In Sync:** Verify that the event check-in window (15 mins prior to 3 hours post-start) evaluates correctly against server UTC time.
- [ ] **Admin Access:** Log in as an admin user to confirm navigation options (`Admin` and `Events`) render correctly.
