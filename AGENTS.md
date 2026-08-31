# Holocron

Holocron is a personal Kindle highlight library. A `Book` owns deduplicated
`Highlight` records, an `Import` records one ingestion operation, and a `Review`
resurfaces a stable daily selection. Obsidian receives one generated note per
book through a git-backed vault.

## Conventions

- Keep domain behavior on models and stateful POROs under `app/models`.
- Put model-specific traits under `app/models/<model>/`; use shared concerns
  only when multiple models genuinely share the trait.
- Keep controllers to CRUD actions and scope every record through `Current.user`.
- Use Minitest fixtures and the existing Rails stack before adding gems.
- Never log Amazon cookies or git tokens. Obsidian content below
  `<!-- holocron:end -->` belongs to the user and must survive every export.
