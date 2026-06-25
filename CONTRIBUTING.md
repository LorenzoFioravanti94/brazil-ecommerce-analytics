# Contributing

This document describes the git workflow, branch conventions, and local development setup for this repository.

---

## Git Workflow

This repository uses a **many-trunks** strategy with two permanent integration branches:

```
feature/*  ──►  develop  ──►  main
```

- **`develop`** is the integration branch. All feature work is merged here first via Pull Request.
- **`main`** receives only promotion PRs from `develop`. It represents the latest stable, deployable state.
- `develop` is never bypassed — changes go through it even for small fixes.
- Both `develop` and `main` are protected by a GitHub ruleset: direct pushes are blocked, PRs are required, the `dbt-ci` status check must pass, and any open conversations must be resolved before merging.
- PRs merge with a **merge commit** — squash and rebase are disabled. Squashing a `develop → main` PR would fold the manifest-bot commit messages into one commit and silently skip deployment; see [CI/CD](.github/CICD.md).

### Branch types

| Prefix | Purpose | Example |
|---|---|---|
| `feature/` | New functionality | `feature/add-delivery-metrics` |
| `fix/` | Bug fixes | `fix/slim-ci-state` |
| `bugfix/` | Alternative bug fix prefix | `bugfix/fix-slim-ci` |
| `refactor/` | Code restructuring without behaviour change | `refactor/rework-repo` |
| `chore/` | Maintenance, deps, docs, tooling | `chore/dbt-project-evaluator-audit` |

New branch names are lowercase, with words separated by hyphens (`-`). No uppercase, no underscores. Existing branches that predate this convention do not need renaming.

### Commit messages

Commit messages are loosely based on [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): short description
```

Common types: `feat`, `fix`, `refactor`, `docs`, `build`, `chore`, `test`.  
The scope is the component or layer affected (e.g. `gold`, `dagster`, `ci`, `staging`).

### PR naming

PR titles follow this format:

```
TARGET BRANCH | <prefix> | [<Layer>] | [<Sublayer>] | <description>
```

`Layer` and `Sublayer` are optional and included only when the work is scoped to a specific pipeline layer.

Examples:
```
DEVELOP | feature | Bronze | created airports model
DEVELOP | refactor | Silver | Staging | normalize city names
MAIN | release | promoted develop to main
```

Fill in the pull request template (`.github/pull_request_template.md`) for every PR.

---

## Local Development Setup

Working on this project requires four terminal sessions running concurrently. Keep them open in separate tabs or a terminal multiplexer. All commands start from the **repo root**.

### Terminal 1 — dbt (warehouse)

```bash
source myvenv/bin/activate
cd warehouse/
```

Common commands:

```bash
dbt build                        # run + test everything
dbt build -s +dim_customers+     # build a model and its parents/children
dbt build --target dev           # explicit dev target (default)
dbt run-operation show_target    # print active connection details
```

### Terminal 2 — Dagster UI (dagster)

```bash
source myvenv/bin/activate
cd dagster/
pip install -e ".[dev]"   # first time only: adds the orchestration package + the dg CLI
dg dev
```

`dg dev` starts the Dagster UI on [http://localhost:3000](http://localhost:3000). The editable install runs once: `requirements.txt` ships the Dagster runtime, not the local `orchestration` package or `dg`.

Ensure `~/.dagster/dagster.yaml` exists (even empty) before starting — Dagster warns at startup if it is missing:

```bash
mkdir -p "$HOME/.dagster" && touch "$HOME/.dagster/dagster.yaml"
```

### Terminal 3 — ngrok (no venv)

Exposes the Dagster webserver to GitHub Actions for the post-merge CD trigger:

```bash
ngrok http 3000
```

Copy the generated HTTPS URL and set it as the `DAGSTER_URL` secret in the repository's GitHub Actions settings (`Settings → Secrets and variables → Actions`).

### Terminal 4 — Git (no venv)

Used for all git operations. No virtual environment needed.
