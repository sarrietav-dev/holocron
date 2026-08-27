# Holocron

Holocron is a self-hosted Kindle highlight library inspired by Readwise. It
imports highlights from Kindle, keeps them searchable and organized, resurfaces
a daily selection in the app and by email, and exports one Markdown note per
book to an Obsidian vault.

The hosted instance is at [holocron.sarrietav.dev](https://holocron.sarrietav.dev).
It is private and does not provide public registration.

## Features

- Import `My Clippings.txt` files directly from a Kindle.
- Sync books and highlights from `read.amazon.com/notebook` with a saved session
  cookie.
- Deduplicate highlights arriving through both Kindle sources.
- Browse books and search highlight text, notes, titles, authors, and tags with
  SQLite FTS5.
- Favorite, dismiss, tag, and annotate highlights.
- Build a stable daily review and deliver it through SMTP.
- Export Markdown to a git-backed Obsidian vault while preserving everything
  below `<!-- holocron:end -->`.
- Run background work with Solid Queue and deploy as one container with Kamal.

## Stack

- Ruby 4.0 and Rails 8.1
- SQLite with FTS5
- Turbo, Stimulus, Importmap, and hand-written CSS
- Solid Queue, Solid Cache, and Solid Cable
- Minitest
- Kamal and Kamal Proxy

## Local Setup

Install Ruby 4.0.6, SQLite with FTS5 support, and libvips. Then run:

```sh
bin/setup
```

The committed credentials file is encrypted for the hosted instance. Generate
your own credentials before storing Amazon or Obsidian secrets:

```sh
rm config/credentials.yml.enc
EDITOR="your-editor --wait" bin/rails credentials:edit
bin/rails db:encryption:init
EDITOR="your-editor --wait" bin/rails credentials:edit
```

Add the three values printed by `db:encryption:init` to credentials:

```yaml
active_record_encryption:
  primary_key: ...
  deterministic_key: ...
  key_derivation_salt: ...
```

Seed the single account and start Rails:

```sh
ADMIN_EMAIL=you@example.com ADMIN_PASSWORD='choose-a-password' bin/rails db:seed
bin/rails server
```

Open <http://localhost:3000> and sign in with the seeded account.

## Kindle Import

### My Clippings

Connect the Kindle over USB and upload `documents/My Clippings.txt` from the
Imports screen. This is the reliable, offline import path.

### Amazon Notebook

Amazon does not provide a public highlights API. Holocron can scrape your own
notebook session:

1. Sign in at <https://read.amazon.com/notebook>.
2. Open browser developer tools and inspect an authenticated notebook request.
3. Copy only the value of its `Cookie` request header.
4. Paste it into Settings and test the connection.

Amazon cookies expire and the notebook markup may change. A layout mismatch or
expired session fails visibly instead of silently importing zero highlights.
Cookie-based scraping may also be subject to Amazon's terms of service.

## Obsidian Export

Configure an HTTPS Git repository, server-side clone path, vault folder, and
access token in Settings. Holocron clones the repository, writes one note per
book, commits, and pushes. An Obsidian Git plugin can pull those changes on a
different machine.

Generated content ends at:

```html
<!-- holocron:end -->
```

Anything below that marker is preserved verbatim across exports. Stable block
IDs also keep Obsidian backlinks and embeds valid after subsequent syncs.

## Search

The search screen accepts text and optional filters:

```text
history tag:philosophy
book:"Sapiens" favorite:true
author:Harari
```

Rebuild the FTS5 index after restoring or modifying the database directly:

```sh
bin/rails holocron:reindex
```

## Email

Production email uses the following environment variables:

```text
SMTP_ADDRESS
SMTP_PORT
SMTP_USER_NAME
SMTP_PASSWORD
SMTP_DOMAIN
SMTP_AUTHENTICATION
SMTP_STARTTLS
MAILER_FROM
APP_HOST
APP_PROTOCOL
```

The scheduler checks hourly and sends each enabled user's review when their
configured local hour arrives.

## Tests

Run the complete local CI pipeline:

```sh
bin/ci
```

It runs RuboCop, dependency audits, Brakeman, the Rails test suite, and seed
verification. System tests can be run separately with `bin/rails test:system`.

## Deployment

The included `config/deploy.yml` demonstrates the live single-server Kamal
deployment with persistent SQLite storage, GHCR, Kamal Proxy TLS, and Solid
Queue inside Puma. It contains owner-specific hosts and image names; change
those values before deploying elsewhere.

Runtime secrets are resolved by `.kamal/secrets` from 1Password and are never
stored in the repository. A deployment needs values for:

```text
KAMAL_REGISTRY_PASSWORD
RAILS_MASTER_KEY
ADMIN_EMAIL
ADMIN_PASSWORD
SMTP_USER_NAME
SMTP_PASSWORD
```

After adapting the deployment configuration:

```sh
bin/kamal setup
bin/kamal app exec "bin/rails db:seed"
```

Back up the persistent volume containing `/rails/storage`; it holds the primary,
cache, queue, and cable SQLite databases as well as local uploaded files.

## Security

- Never commit Amazon cookies, Git tokens, SMTP passwords, or
  `config/master.key`.
- Credentials stored through the app are encrypted with Active Record
  Encryption.
- Every controller scopes records through the authenticated user.
- Obsidian output paths are constrained to the configured vault folder.
- Git credentials are supplied through a temporary askpass helper and are not
  written to `.git/config`.
