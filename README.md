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
* **OAuth Owner:** Qayyum Alli
* **Production Deployment:** Deployed on Heroku with production database connections handled automatically via `DATABASE_URL`. OAuth credentials (Client ID and Secret) are stored securely in Heroku Config Vars.
* **Local & Docker Setup:** Uses PostgreSQL adapter (`pg` gem). Secrets are injected dynamically via environment variables in accordance with 12-factor app practices and are never hardcoded.
