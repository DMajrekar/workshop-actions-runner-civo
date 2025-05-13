#!/bin/bash
# Script to trigger the process-single-job workflow in a GitHub repository
# chmod +x scripts/trigger_single_job.sh to make executable

set -e

echo "==============================================="
echo "     Triggering Single Process Job Workflow    "
echo "==============================================="

# Check if GitHub user and repo are provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <github_username> <repository_name>"
  echo "Example: $0 johndoe my-runner-repo"
  exit 1
fi

GITHUB_USERNAME=$1
REPOSITORY_NAME=$2
FULL_REPO_PATH="$GITHUB_USERNAME/$REPOSITORY_NAME"

echo "Triggering workflow in repository: $FULL_REPO_PATH"

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
  echo "GitHub CLI (gh) is not installed. Please install it first:"
  echo "https://cli.github.com/manual/installation"
  exit 1
fi

# Check if user is authenticated with GitHub CLI
if ! gh auth status &> /dev/null; then
  echo "You need to authenticate with GitHub CLI first:"
  echo "gh auth login"
  exit 1
fi

# Trigger the workflow using GitHub CLI
echo "Dispatching workflow 'process-single-job.yml'..."

# Use individual parameters instead of JSON payload
gh workflow run process-single-job.yml --repo $FULL_REPO_PATH \
  --ref main \
  --raw-field job_id="single-process-demo" \
  --raw-field duration="5"

echo "Workflow triggered successfully!"
echo "To monitor the job, visit: https://github.com/$FULL_REPO_PATH/actions"
echo
echo "Monitor your runner with:"
echo "kubectl get pods -n actions-runner-system -w"
