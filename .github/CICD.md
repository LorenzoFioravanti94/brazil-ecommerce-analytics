# CI/CD

This folder holds the GitHub Actions automation that ties the `warehouse` dbt project and the `dagster` orchestration layer together. It is the most intricate subsystem in the repository: three workflows form a closed loop around a single shared artifact, the committed dbt manifest.

```
.github/
├── workflows/
│   ├── ci.yml                          ← PR gate (Slim CI / Full CI)
│   ├── dagster-cd.yml                  ← CD: trigger Dagster after merge to main
│   └── post-deploy-update-manifest.yml ← refresh the reference manifest
└── pull_request_template.md            ← PR checklist
```

---

## The Manifest Loop

Everything here revolves around `persistent_state/manifest.json` (committed at the repo root). It is the **reference state** Slim CI compares against to decide what changed.

```
PR → develop ──────► ci.yml          Slim CI: build only what changed vs main
PR → main ─────────► ci.yml          Full CI: build everything
merge → main ──────► dagster-cd.yml  reload Dagster + run standard_job (CD)
                          │
                     on success
                          ▼
              post-deploy-update-manifest.yml
                          │
                  dbt parse on main → regenerate manifest
                          │
                  commit back to persistent_state/manifest.json
                          │
                          └─► next Slim CI now compares against the new baseline
```

The loop is self-correcting: every successful deploy to `main` refreshes the baseline, so the *next* PR towards `develop` is measured against the latest production state — never against a stale manifest.

---

## `ci.yml` — Pull Request Gate

Runs on every PR targeting `develop` or `main`. It provisions a throwaway environment from scratch (install dbt pins, download the Kaggle datasets, ingest into a fresh `data/duckdb/test.duckdb`), then branches on the target:

### Slim CI (PR → `develop`)

Builds only the models affected by the change, keeping CI fast on incremental work.

1. **Fetch the baseline** — checks out `persistent_state/manifest.json` from `origin/main` (overwriting only that file, leaving the PR's code intact). This is the comparison state.
2. **Build the `slim_ci` selector** with `--state persistent_state`. The selector (defined in `warehouse/selectors.yml`) is the union of three criteria:
   - `state:modified, parents:true` — changed nodes **and their ancestors**, so inputs are present. Children are excluded on purpose (facts FK every dimension, but dimensions are not upstream of facts).
   - `tag:always_build` — standalone models like `dim_date` that `state:modified` never picks up, yet facts' relationship tests need present.
   - `resource_type:seed` — all seeds, because the CI database starts empty and any `ref()` to an unbuilt seed would fail.

> **`indirect_selection: cautious` is load-bearing.** A test attaches only when *all* the models it references are in the build set. This intentionally skips cross-dimension FK tests under Slim CI (they are covered by Full CI on the `develop → main` promotion). The dbt default of `eager` would break Slim CI on tests of dimensions that were never built.

> **No `--defer`.** CI has no prod database to defer unbuilt nodes to, so the fresh test DB must physically contain everything the selected nodes read. That is exactly what the seed + `always_build` criteria guarantee.

### Full CI (PR → `main`)

A plain `dbt build` of the entire project. A promotion PR from `develop` to `main` never merges on less than a full, green build.

### Version guard

Before anything runs, the workflow asserts `dbt-core == 1.11.8` — the version that produced the reference manifest. A silent dbt upgrade would change the manifest schema and produce false `state:modified` results, so it fails loudly instead.

---

## `dagster-cd.yml` — Continuous Deployment

Runs on `push` to `main`. It calls `scripts/dagster_trigger.py`, which talks to the self-hosted Dagster instance (exposed via ngrok) over GraphQL: it **reloads the code location** so the freshly merged dbt project is re-parsed into a current manifest, then launches `standard_job` and waits for it.

The reload is mandatory — without it Dagster keeps the manifest it loaded at startup, and `dagster-dbt` raises `KeyError` the moment a renamed node is missing from that stale copy.

> **Loop guard.** The job skips any commit whose message contains `update persistent_state manifest`. That message is produced by the next workflow, which also pushes to `main`; without the guard, that bot commit would re-trigger this CD workflow forever.

---

## `post-deploy-update-manifest.yml` — Baseline Refresh

Triggered by `workflow_run` after `dagster-cd` **succeeds**. It checks out `main`, runs `dbt parse` (no database needed — parsing is enough to emit a manifest), and commits the result back to `persistent_state/manifest.json`.

Three safeguards make this safe to run unattended:

- **Matching profile.** Parses with the committed `warehouse/profiles.yml` on `target: test`, the same profile `ci.yml` uses. The database name must align, or `state:modified` flags every source against the Slim CI baseline.
- **`duckdb` poison guard.** If the generated manifest contains the string `"javascript"`, it aborts before committing. See the landmine below.
- **Rebase before push.** It runs `git pull --rebase origin main` before pushing, so a commit that landed concurrently doesn't leave the manifest stale with no retry.

---

## The `duckdb == 1.0.0` Landmine

The manifest must be generated with `duckdb` pinned to **exactly `1.0.0`** (see `requirements-dbt.txt`). Any other version serializes adapter types into the manifest as the literal string `"javascript"`, which dbt **cannot read back** via `--state`. A poisoned manifest silently breaks *every* subsequent Slim CI run.

This is why `post-deploy-update-manifest.yml` greps for `"javascript"` and fails rather than committing a broken baseline.

---

## Secrets

Configure these under `Settings → Secrets and variables → Actions`:

| Secret | Used by | Purpose |
|---|---|---|
| `KAGGLE_API_TOKEN` | `ci.yml` | Download the Olist and IBGE datasets for the throwaway CI build |
| `DAGSTER_URL` | `dagster-cd.yml` | Base URL of the self-hosted Dagster instance (the ngrok HTTPS tunnel) |
| `MANIFEST_PAT` | `post-deploy-update-manifest.yml` | Personal access token allowing the bot to push the refreshed manifest to protected `main` |

The ngrok tunnel that backs `DAGSTER_URL` must be running for the CD trigger to reach Dagster — see [`../CONTRIBUTING.md`](../CONTRIBUTING.md) for the local terminal setup.

---

## Pull Request Template

`pull_request_template.md` pre-fills every PR with a review checklist. PR **titles** follow the convention documented in [`../CONTRIBUTING.md`](../CONTRIBUTING.md#pr-naming); the template covers the body.
