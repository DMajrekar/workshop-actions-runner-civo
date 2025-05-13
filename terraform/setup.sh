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

# Check if GitHub token already exists in tfvars file
if grep -q "github_token" terraform.tfvars; then
    echo "GitHub token already exists in terraform.tfvars. It will be used for deployment."
    # Extract the token from terraform.tfvars
    github_token=$(grep "github_token" terraform.tfvars | cut -d'"' -f2)
    echo "Using existing GitHub token..."
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

    # Save the token to terraform.tfvars for future use
    echo "" >> terraform.tfvars
    echo "# GitHub Personal Access Token" >> terraform.tfvars
    echo "github_token = \"$github_token\"" >> terraform.tfvars
    echo "GitHub token saved to terraform.tfvars"
fi

# Get GitHub repository information at the beginning
echo
read -p "Enter your GitHub username: " github_username
read -p "Enter the repository name: " github_repo

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Apply Terraform configuration with GitHub PAT
echo
echo "Creating Civo Kubernetes cluster with Actions Runner Controller and Cluster Autoscaler..."
echo "This will take a few minutes..."
terraform apply -auto-approve \
  -var="github_token=$github_token"

# Get kubeconfig and setup kubectl
echo
echo "Setting up kubeconfig..."
export KUBECONFIG=$(terraform output -raw kubeconfig_path)
echo "Kubeconfig configured at: $KUBECONFIG"

# Verify connection
echo
echo "Verifying connection to the cluster..."
kubectl cluster-info

# Setup repository runner deployment
echo
echo "Using GitHub repository: $github_username/$github_repo"

cat > runner-deployment.yaml << EOF
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: github-runner
spec:
  replicas: 1
  template:
    spec:
      repository: $github_username/$github_repo
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

# Deploy runner configuration
echo
echo "Deploying runner configuration..."
kubectl apply -f runner-deployment.yaml

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
