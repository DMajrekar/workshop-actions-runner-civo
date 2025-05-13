#!/bin/bash
# This script removes GitHub Actions Runners and destroys the Terraform infrastructure

set -e

# Make the script executable
chmod +x "$0"

# ASCII art banner
echo "=================================================="
echo "  GitHub Actions Runners Cleanup Script"
echo "=================================================="
echo

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if kubeconfig exists
if [ -f "$(terraform output -raw kubeconfig_path 2>/dev/null)" ]; then
    export KUBECONFIG=$(terraform output -raw kubeconfig_path)
    echo "Using kubeconfig at: $KUBECONFIG"
else
    echo "WARNING: Kubeconfig not found or cluster already destroyed."
    echo "Will proceed with terraform destroy only."
    SKIP_RUNNER_CLEANUP=true
fi

# Obtain GitHub repository information
if [ "$SKIP_RUNNER_CLEANUP" != "true" ]; then
    # Try to get repository info from the runner deployment
    if kubectl get runnerdeployment github-runner -n actions-runner-system &>/dev/null; then
        REPO_INFO=$(kubectl get runnerdeployment github-runner -n actions-runner-system -o jsonpath='{.spec.template.spec.repository}')
        echo "Found runner for repository: $REPO_INFO"
        
        # Parse username and repo
        GITHUB_USERNAME=$(echo $REPO_INFO | cut -d'/' -f1)
        GITHUB_REPO=$(echo $REPO_INFO | cut -d'/' -f2)
        
        echo "GitHub Username: $GITHUB_USERNAME"
        echo "GitHub Repository: $GITHUB_REPO"
    else
        echo "Unable to automatically determine repository info."
        read -p "Enter your GitHub username: " GITHUB_USERNAME
        read -p "Enter your repository name: " GITHUB_REPO
    fi
    
    # Delete runner deployments and autoscalers
    echo
    echo "Removing runner deployments and autoscalers..."
    kubectl delete horizontalrunnerautoscaler --all -n actions-runner-system --ignore-not-found=true
    kubectl delete runnerdeployment --all -n actions-runner-system --ignore-not-found=true
    kubectl delete runner --all -n actions-runner-system --ignore-not-found=true
    
    echo "Waiting for runners to be removed from Kubernetes (30 seconds)..."
    sleep 30
    
    # Check if GitHub token exists in tfvars
    if grep -q "github_token" terraform.tfvars; then
        GITHUB_TOKEN=$(grep "github_token" terraform.tfvars | cut -d'"' -f2)
        echo "Found GitHub token in terraform.tfvars"
        
        # Attempt to remove orphaned runners from GitHub
        echo "Checking for orphaned runners in GitHub..."
        
        # Get list of runners with API
        RUNNERS_JSON=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
                           -H "Accept: application/vnd.github.v3+json" \
                           "https://api.github.com/repos/$GITHUB_USERNAME/$GITHUB_REPO/actions/runners")
        
        # Check if successful
        if [[ $RUNNERS_JSON == *"\"runners\":"* ]]; then
            RUNNERS=$(echo $RUNNERS_JSON | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
            
            if [ -z "$RUNNERS" ]; then
                echo "No GitHub runners found for $GITHUB_USERNAME/$GITHUB_REPO"
            else
                echo "Found GitHub runners, attempting to remove them..."
                
                for RUNNER_ID in $RUNNERS; do
                    echo "Removing runner $RUNNER_ID..."
                    curl -s -X DELETE -H "Authorization: token $GITHUB_TOKEN" \
                         -H "Accept: application/vnd.github.v3+json" \
                         "https://api.github.com/repos/$GITHUB_USERNAME/$GITHUB_REPO/actions/runners/$RUNNER_ID"
                done
                
                echo "GitHub runners cleanup complete."
            fi
        else
            echo "Unable to retrieve runners from GitHub API. Check your token permissions."
        fi
    else
        echo "GitHub token not found in terraform.tfvars. Skipping GitHub API cleanup."
        echo "You may need to manually remove runners from your GitHub repository."
    fi
fi

# Destroy Terraform infrastructure
echo
echo "Destroying Terraform infrastructure..."
terraform destroy -auto-approve

echo
echo "======================================================================"
echo "Cleanup complete!"
echo "======================================================================"