#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PIER_DIR="${PIER_DIR:-$WORKSPACE_ROOT/pier}"
TASKS_DIR="${TASKS_DIR:-$SCRIPT_DIR/tasks}"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.env}"
JOBS_DIR="${JOBS_DIR:-$SCRIPT_DIR/jobs}"
JOB_NAME="${JOB_NAME:-swe-xplorer-gpt5-mini}"
JOB_DIR="$JOBS_DIR/$JOB_NAME"
AGENT="${AGENT:-tree-search-mini-swe-agent}"
MODEL="${MODEL:-openrouter/openai/gpt-5-mini}"
N_CONCURRENT="${N_CONCURRENT:-1}"
N_TASKS="${N_TASKS-}"
SAMPLE_SEED="${SAMPLE_SEED-}"

if ! command -v uv >/dev/null 2>&1; then
  echo "uv is required: https://docs.astral.sh/uv/" >&2
  exit 2
fi

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE. Add OPENROUTER_API_KEY before running." >&2
  exit 2
fi

if [[ -f "$JOB_DIR/config.json" ]]; then
  echo "Resuming $JOB_NAME; completed instances will be skipped."
  exec uv run --project "$PIER_DIR" pier job resume --job-path "$JOB_DIR"
fi

if [[ -e "$JOB_DIR" ]]; then
  echo "$JOB_DIR exists but is not a resumable Pier job (config.json is missing)." >&2
  exit 2
fi

dataset_args=()
if [[ -n "$N_TASKS" ]]; then
  dataset_args+=(--n-tasks "$N_TASKS")
fi
if [[ -n "$SAMPLE_SEED" ]]; then
  dataset_args+=(--sample-seed "$SAMPLE_SEED")
fi

exec uv run --project "$PIER_DIR" pier run \
  --path "$TASKS_DIR" \
  --agent "$AGENT" \
  --model "$MODEL" \
  --env-file "$ENV_FILE" \
  --jobs-dir "$JOBS_DIR" \
  --job-name "$JOB_NAME" \
  --n-concurrent "$N_CONCURRENT" \
  "${dataset_args[@]}" \
  --yes
