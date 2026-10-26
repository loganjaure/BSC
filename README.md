# BSC-500 Attendance Application

A concise description of the project, its core functionality, and its purpose.

## Table of Contents

* [Getting Started](#getting-started)
  * [Prerequisites](#prerequisites)
  * [Installation](#installation)
* [Running Tests Locally](#running-tests-locally)
* [CI/CD Pipeline & Deployment](#cicd-pipeline--deployment)
* [Configuration Items List](#configuration-items-list)
* [OAuth & Environment Configuration Notice](#oauth--environment-configuration-notice)

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
   git clone https://github.com/your-username/your-repo-name.git
   cd your-repo-name
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
| **Deployed code** | Git Commit `7283aca` (GitHub) / `7283acad` (Heroku Release) | GitHub repository commit history / Heroku deployment pipeline |
| **Runtime/framework** | Ruby 3.4.6 with Rails 8.0 | `Dockerfile` (`ARG RUBY_VERSION=3.4.6`), `.ruby-version`, and `Gemfile` |
| **Dependencies** | Locked Gem versions (`pg`), multi-stage Docker build (`ruby:3.4.6-slim`) | `Gemfile.lock` and `Dockerfile` |
| **Database and deployment environment** | PostgreSQL (`bsc_500_development` locally, Heroku Postgres via `DATABASE_URL` in production) | `config/database.yml` and Heroku Add-ons dashboard |
| **Supporting instructions** | OAuth configurations, owner details (Qayyum Alli), and deployment guidance | `README.md` and Heroku Config Vars (`OAUTH_CLIENT_ID`, `OAUTH_CLIENT_SECRET`) |

---

### OAuth & Environment Configuration Notice
- **OAuth Owner:** Qayyum Alli
- **Production Deployment:** Deployed on Heroku with production database connections handled automatically via `DATABASE_URL`. OAuth credentials (Client ID and Secret) are stored securely in Heroku Config Vars.
- **Local & Docker Setup:** Uses PostgreSQL adapter (`pg` gem). Secrets are injected dynamically via environment variables in accordance with 12-factor app practices and are never hardcoded.
