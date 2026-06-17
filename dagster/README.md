# dagster

## Getting started

### Installing dependencies

**Option 1: uv**

Ensure [`uv`](https://docs.astral.sh/uv/) is installed following their [official documentation](https://docs.astral.sh/uv/getting-started/installation/).

Create a virtual environment, and install the required dependencies using _sync_:

```bash
uv sync
```

Then, activate the virtual environment:

| OS | Command |
| --- | --- |
| MacOS | ```source .venv/bin/activate``` |
| Windows | ```.venv\Scripts\activate``` |

**Option 2: pip**

Install the python dependencies with [pip](https://pypi.org/project/pip/):

```bash
python3 -m venv .venv
```

Then activate the virtual environment:

| OS | Command |
| --- | --- |
| MacOS | ```source .venv/bin/activate``` |
| Windows | ```.venv\Scripts\activate``` |

Install the required dependencies:

```bash
pip install -e ".[dev]"
```

### Running Dagster

Dagster needs a `dagster.yaml` in its instance home (`DAGSTER_HOME`, default
`~/.dagster`). Create an empty one there once so Dagster does not warn at startup:

```bash
mkdir -p "$HOME/.dagster" && touch "$HOME/.dagster/dagster.yaml"
```

Then start the UI web server from this `dagster/` project root (`dg` auto-discovers
the code location from `pyproject.toml`, so no `-m` flag is needed):

```bash
dg dev
```

Open http://localhost:3000 in your browser to see the project.

> Note: do not keep a `dagster.yaml` inside this project folder while
> `DAGSTER_HOME` points elsewhere — Dagster warns that the local file is ignored.
> Instance config belongs in `DAGSTER_HOME` (`~/.dagster`).

## Learn more

To learn more about this template and Dagster in general:

- [Dagster Documentation](https://docs.dagster.io/)
- [Dagster University](https://courses.dagster.io/)
- [Dagster Slack Community](https://dagster.io/slack)
