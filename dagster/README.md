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

Point `DAGSTER_HOME` at this project directory (it holds `dagster.yaml`) and start
the Dagster UI web server:

```bash
export DAGSTER_HOME="$(pwd)"   # run from the dagster/ project root
dg dev
```

Open http://localhost:3000 in your browser to see the project.

Setting `DAGSTER_HOME` to the directory containing `dagster.yaml` keeps instance
storage local to the project and silences the "No dagster instance configuration
file found" startup warning. The local instance storage it creates
(`storage/`, `history/`, `schedules/`, `logs/`) is gitignored.

## Learn more

To learn more about this template and Dagster in general:

- [Dagster Documentation](https://docs.dagster.io/)
- [Dagster University](https://courses.dagster.io/)
- [Dagster Slack Community](https://dagster.io/slack)
