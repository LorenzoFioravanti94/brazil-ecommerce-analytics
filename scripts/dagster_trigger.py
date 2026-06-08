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

LOCATION = "orchestration.definitions"
REPOSITORY = "__repository__"
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

STATUS_QUERY = """
query Status($runId: ID!) {
  runOrError(runId: $runId) {
    __typename
    ... on Run { status }
  }
}
"""


def reload_location() -> None:
    """Re-parse the merged project so the manifest is current before the run."""
    result = graphql(RELOAD_MUTATION, {"name": LOCATION})["reloadRepositoryLocation"]
    if result["__typename"] != "WorkspaceLocationEntry":
        sys.exit(f"Code location reload failed: {result.get('message', result)}")
    load = result["locationOrLoadError"]
    if load["__typename"] != "RepositoryLocation":
        sys.exit(f"Code location reload error: {load.get('message', load)}")
    print(f"Reloaded code location '{LOCATION}'")


def launch_run() -> str:
    """Launch standard_job and return its run id."""
    params = {
        "selector": {
            "repositoryLocationName": LOCATION,
            "repositoryName": REPOSITORY,
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
    reload_location()
    run_id = launch_run()
    wait_for_run(run_id)


if __name__ == "__main__":
    main()
