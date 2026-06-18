"""Trigger the Dagster `standard_job` after a merge to main.

Runs in GitHub Actions and talks to the self-hosted Dagster (exposed via ngrok)
over GraphQL. It first reloads the code location so the freshly merged dbt
project is re-parsed into a current manifest — otherwise Dagster keeps the
in-memory manifest loaded at startup and dagster-dbt raises KeyError when a
renamed node is missing from it — then launches the job and waits for it.

Note: the reload re-parses the dbt project from the local disk, so the host
must already be on the merged code; GitHub Actions cannot pull it remotely.

Required env vars:
  DAGSTER_URL  base URL of the Dagster instance (without the /graphql suffix).
"""
from __future__ import annotations

import json
import os
import sys
import time
import urllib.request

DAGSTER_URL = os.environ["DAGSTER_URL"].rstrip("/")
GRAPHQL_URL = f"{DAGSTER_URL}/graphql"

# Only the job name is fixed; the code-location and repository names that own it
# are discovered at runtime.
JOB = "standard_job"

POLL_INTERVAL_SECONDS = 30
RUN_TIMEOUT_SECONDS = 30 * 60


def graphql(query: str, variables: dict | None = None) -> dict:
    """POST a GraphQL document and return its `data` payload, or exit on error."""

    payload = json.dumps({"query": query, "variables": variables or {}}).encode()
    request = urllib.request.Request(
        GRAPHQL_URL, data=payload, headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(request) as response:
        body = json.load(response)
    if body.get("errors"):
        sys.exit(f"GraphQL errors: {json.dumps(body['errors'])}")
    return body["data"]


# Lists every code location / repository and its jobs, to find which one owns JOB.
DISCOVER_QUERY = """
query Discover {
  repositoriesOrError {
    __typename
    ... on RepositoryConnection {
      nodes {
        name
        location { name }
        pipelines { name }
      }
    }
    ... on PythonError { message }
  }
}
"""

# Reloads a code location, re-parsing the dbt project into a fresh manifest.
RELOAD_MUTATION = """
mutation Reload($name: String!) {
  reloadRepositoryLocation(repositoryLocationName: $name) {
    __typename
    ... on WorkspaceLocationEntry {
      locationOrLoadError {
        __typename
        ... on PythonError { message }
      }
    }
    ... on ReloadNotSupported { message }
    ... on RepositoryLocationNotFound { message }
  }
}
"""

# Launches a run of the selected job and returns its run id.
LAUNCH_MUTATION = """
mutation Launch($params: ExecutionParams!) {
  launchRun(executionParams: $params) {
    __typename
    ... on LaunchRunSuccess { run { runId } }
    ... on PythonError { message }
    ... on RunConfigValidationInvalid { errors { message } }
    ... on PipelineNotFoundError { message }
  }
}
"""

# Polls a single run's current status (used to wait for the job to finish).
STATUS_QUERY = """
query Status($runId: ID!) {
  runOrError(runId: $runId) {
    __typename
    ... on Run { status }
  }
}
"""


def discover_target() -> tuple[str, str]:
    """Find the code-location and repository names that own JOB.

    Returns (location_name, repository_name) so the caller never has to hardcode
    names that shift with the Dagster project layout or launch command.
    """

    result = graphql(DISCOVER_QUERY)["repositoriesOrError"]
    if result["__typename"] != "RepositoryConnection":
        sys.exit(f"Failed to list repositories: {result.get('message', result)}")
    for repo in result["nodes"]:
        if any(pipeline["name"] == JOB for pipeline in repo["pipelines"]):
            location = repo["location"]["name"]
            repository = repo["name"]
            print(f"Discovered job '{JOB}' in '{location}' / '{repository}'")
            return location, repository
    sys.exit(f"No code location exposes a job named '{JOB}'")


def reload_location(location: str) -> None:
    """Re-parse the merged project so the manifest is current before the run."""

    result = graphql(RELOAD_MUTATION, {"name": location})["reloadRepositoryLocation"]
    if result["__typename"] != "WorkspaceLocationEntry":
        sys.exit(f"Code location reload failed: {result.get('message', result)}")
    load = result["locationOrLoadError"]
    if load["__typename"] != "RepositoryLocation":
        sys.exit(f"Code location reload error: {load.get('message', load)}")
    print(f"Reloaded code location '{location}'")


def launch_run(location: str, repository: str) -> str:
    """Launch standard_job and return its run id."""

    params = {
        "selector": {
            "repositoryLocationName": location,
            "repositoryName": repository,
            "jobName": JOB,
        },
        "runConfigData": {},
    }
    result = graphql(LAUNCH_MUTATION, {"params": params})["launchRun"]
    if result["__typename"] != "LaunchRunSuccess":
        sys.exit(f"launchRun failed: {result}")
    run_id = result["run"]["runId"]
    print(f"Launched {JOB} run {run_id}")
    return run_id


def wait_for_run(run_id: str) -> None:
    """Poll the run until it reaches a terminal state, or exit on timeout."""

    deadline = time.time() + RUN_TIMEOUT_SECONDS
    while time.time() < deadline:
        data = graphql(STATUS_QUERY, {"runId": run_id})["runOrError"]
        status = data.get("status", "UNKNOWN")
        print(f"Run status: {status}")
        if status == "SUCCESS":
            print("Dagster job completed successfully")
            return
        if status in ("FAILURE", "CANCELED"):
            sys.exit(f"Dagster run ended with status {status}")
        time.sleep(POLL_INTERVAL_SECONDS)
    sys.exit("Timeout: Dagster run did not finish within 30 minutes")


def main() -> None:
    location, repository = discover_target()
    reload_location(location)
    run_id = launch_run(location, repository)
    wait_for_run(run_id)


if __name__ == "__main__":
    main()
