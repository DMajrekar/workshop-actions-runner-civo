#!/bin/bash
# This script simplifies the process of setting up a Civo Kubernetes cluster
# and the Actions Runner Controller for workshop participants

set -e

# ASCII art banner
echo "=================================================="
echo "  GitHub Actions Runners on Civo Kubernetes Workshop"
echo "=================================================="
echo

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Terraform is not installed. Please install Terraform first."
    echo "Visit: https://developer.hashicorp.com/terraform/downloads"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Please install kubectl first."
    echo "Visit: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "Helm is not installed. Please install Helm first."
    echo "Visit: https://helm.sh/docs/intro/install/"
    exit 1
fi

# Check if tfvars file exists, if not create it
if [ ! -f terraform.tfvars ]; then
    echo "terraform.tfvars file not found."
    echo "Creating a new one from the example file..."
    
    if [ ! -f terraform.tfvars.example ]; then
        echo "terraform.tfvars.example not found!"
        exit 1
    fi
    
    cp terraform.tfvars.example terraform.tfvars
    
    echo "Please edit terraform.tfvars and add your Civo API token."
    echo "You can get your token from: https://dashboard.civo.com/security"
    exit 1
fi

# Collect all required inputs at the beginning
echo "Collecting all required inputs..."

# Get GitHub repository information first
echo
if grep -q "github_username" terraform.tfvars && grep -q "github_repo" terraform.tfvars; then
    # Extract values from terraform.tfvars
    github_username=$(grep "github_username" terraform.tfvars | cut -d'"' -f2)
    github_repo=$(grep "github_repo" terraform.tfvars | cut -d'"' -f2)
    echo "Using existing GitHub repository: $github_username/$github_repo"
else
    read -p "Enter your GitHub username: " github_username
    read -p "Enter the repository name: " github_repo
    
    # Save repository info to terraform.tfvars
    echo "" >> terraform.tfvars
    echo "# GitHub Username and Repository" >> terraform.tfvars
    echo "github_username = \"$github_username\"" >> terraform.tfvars
    echo "github_repo = \"$github_repo\"" >> terraform.tfvars
fi

# Check if GitHub token already exists in tfvars file
if grep -q "github_token" terraform.tfvars; then
    echo "GitHub token already exists in terraform.tfvars. It will be used for deployment."
    # Extract the token from terraform.tfvars
    github_token=$(grep "github_token" terraform.tfvars | cut -d'"' -f2)
    echo "Using existing GitHub token..."
    
    # Validate the existing token against GitHub API
    echo "Validating the GitHub PAT..."
    repo_access_check=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $github_token" "https://api.github.com/repos/$github_username/$github_repo")

    if [ "$repo_access_check" != "200" ]; then
        echo "Error: The GitHub PAT in terraform.tfvars cannot access the repository $github_username/$github_repo."
        echo "HTTP response code: $repo_access_check"
        echo "Please enter a new token with the correct 'repo' scope."
        read -p "Enter your GitHub Personal Access Token: " github_token
        
        # Update the token in terraform.tfvars
        sed -i "s/github_token = \".*\"/github_token = \"$github_token\"/g" terraform.tfvars
        echo "GitHub token updated in terraform.tfvars"
    else
        # Check for repo scope
        scopes_check=$(curl -s -I -H "Authorization: token $github_token" "https://api.github.com/repos/$github_username/$github_repo" | grep -i "x-oauth-scopes:" | tr -d '\r')

        if [[ ! "$scopes_check" =~ "repo" ]]; then
            echo "Error: The GitHub PAT in terraform.tfvars does not have the required 'repo' scope."
            echo "Current scopes: $scopes_check"
            echo "Please enter a new token with the 'repo' scope enabled."
            read -p "Enter your GitHub Personal Access Token: " github_token
            
            # Update the token in terraform.tfvars
            sed -i "s/github_token = \".*\"/github_token = \"$github_token\"/g" terraform.tfvars
            echo "GitHub token updated in terraform.tfvars"
        else
            echo "GitHub PAT validation successful! The token has the required access and scopes."
        fi
    fi
else
    # Get GitHub PAT information
    echo
    echo "Now we need to set up the GitHub Personal Access Token for Actions Runner Controller"
    echo "Have you created a GitHub PAT with the required permissions?"
    read -p "Yes/No: " created_pat

    if [[ $created_pat != "Yes" && $created_pat != "yes" && $created_pat != "Y" && $created_pat != "y" ]]; then
        echo
        echo "Please create a GitHub Personal Access Token first. Follow these steps:"
        echo "1. Go to your GitHub account settings > Developer settings > Personal access tokens > Tokens (classic)"
        echo "2. Click 'Generate new token' > 'Generate new token (classic)'"
        echo "3. Configure the token:"
        echo "   - Name: Actions Runner Controller Workshop"
        echo "   - Expiration: Set an appropriate expiration (e.g., 7 days)"
        echo "   - Scopes: Select 'repo' (Full control of private repositories)"
        echo "4. Click 'Generate token' and save the token immediately"
        echo
        echo "After completing these steps, run this script again."
        exit 1
    fi

    # Get GitHub PAT information
echo
read -p "Enter your GitHub Personal Access Token: " github_token

# Validate the PAT against GitHub API
echo "Validating the GitHub PAT..."
repo_access_check=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $github_token" "https://api.github.com/repos/$github_username/$github_repo")

if [ "$repo_access_check" != "200" ]; then
    echo "Error: The GitHub PAT provided cannot access the repository $github_username/$github_repo."
    echo "HTTP response code: $repo_access_check"
    echo "Please check that the token is valid and has the correct 'repo' scope."
    exit 1
fi

# Check for repo scope specifically
scopes_check=$(curl -s -I -H "Authorization: token $github_token" "https://api.github.com/repos/$github_username/$github_repo" | grep -i "x-oauth-scopes:" | tr -d '\r')

if [[ ! "$scopes_check" =~ "repo" ]]; then
    echo "Error: The GitHub PAT does not have the required 'repo' scope."
    echo "Current scopes: $scopes_check"
    echo "Please create a new token with the 'repo' scope enabled."
    exit 1
fi

echo "GitHub PAT validation successful! The token has the required access and scopes."

# Save the token to terraform.tfvars for future use
echo "" >> terraform.tfvars
echo "# GitHub Personal Access Token" >> terraform.tfvars
echo "github_token = \"$github_token\"" >> terraform.tfvars
echo "GitHub token saved to terraform.tfvars"
fi

# GitHub repository info already collected above

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Apply Terraform configuration with GitHub PAT
echo
echo "Creating Civo Kubernetes cluster with Actions Runner Controller and Cluster Autoscaler..."
echo "This will take a few minutes..."
terraform apply -auto-approve

# Get kubeconfig and setup kubectl
echo
echo "Setting up kubeconfig..."
export KUBECONFIG=$(terraform output -raw kubeconfig_path)
echo "Kubeconfig configured at: $KUBECONFIG"

# Verify connection
echo
echo "Verifying connection to the cluster..."
kubectl cluster-info

# Setup repository runner deployment - only if not using Terraform to create it
if ! grep -q "github_username" terraform.tfvars || ! grep -q "github_repo" terraform.tfvars; then
    echo
    echo "Repository information not found in terraform.tfvars. Creating runner deployment manually."
    echo "Using GitHub repository: $github_username/$github_repo"

    # Make sure to use the values from script variables
    repository_path="$github_username/$github_repo"

    cat > runner-deployment.yaml << EOF
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: github-runner
spec:
  replicas: 1
  template:
    spec:
      repository: $repository_path
      labels:
        - self-hosted
        - linux
        - x64
      resources:
        limits:
          cpu: "1000m"
          memory: "2Gi"
        requests:
          cpu: "500m"
          memory: "1Gi"
---
apiVersion: actions.summerwind.dev/v1alpha1
kind: HorizontalRunnerAutoscaler
metadata:
  name: github-runner-autoscaler
spec:
  scaleTargetRef:
    name: github-runner
  minReplicas: 1
  maxReplicas: 20
  metrics:
  - type: TotalNumberOfQueuedAndInProgressWorkflowRuns
    scaleUpThreshold: '2'
    scaleDownThreshold: '1'
    scaleUpFactor: '2'
    scaleDownFactor: '0.5'
EOF

    # Deploy runner configuration manually with kubectl
    echo
    echo "Deploying runner configuration with kubectl..."
    kubectl apply -f runner-deployment.yaml
else
    echo
    echo "Using Terraform to deploy runner configuration for repository: $github_username/$github_repo"
fi

# Final instructions
echo
echo "======================================================================"
echo "Setup complete! Your runners should start automatically when jobs are"
echo "triggered in your GitHub repository/organization."
echo
echo "To monitor your runners, run:"
echo "  kubectl get pods -n actions-runner-system -w"
echo
echo "To view the logs of the controller:"
echo "  kubectl logs -n actions-runner-system deployment/actions-runner-controller-actions-runner-controller"
echo
echo "To verify that your runners are registered in GitHub:"
echo "  Go to your GitHub repository > Settings > Actions > Runners"
echo
echo "To check cluster and pod resource utilization using metrics-server:"
echo "  kubectl top nodes        # View node CPU and memory usage"
echo "  kubectl top pods -A      # View all pod resource usage"
echo "  kubectl top pods -n actions-runner-system  # View runner pod resource usage"
echo
echo "The Civo cluster autoscaler has been installed and configured. It will"
echo "automatically scale your cluster nodes when needed based on pending pods."
echo "To check the autoscaler status, run:"
echo "  kubectl get pods -n kube-system | grep cluster-autoscaler"
echo "  kubectl logs -n kube-system deployment/cluster-autoscaler"
echo
echo "You can now use the GitHub workflows in this repository to test your runners."
echo "When workflow demand increases, runners will scale up and the cluster"
echo "autoscaler will provision additional nodes as needed."
echo "======================================================================"
