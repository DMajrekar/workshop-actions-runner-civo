# Terraform Integration for GitHub Actions Runner Workshop

This directory contains the Terraform configuration for creating a Kubernetes cluster on Civo that will host your GitHub Actions self-hosted runners.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 or higher)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- A Civo account with an API key
- A GitHub account with permissions to create GitHub Apps

## Setup Instructions

1. **Create a GitHub App for runner authentication:**
   - Go to GitHub Settings > Developer settings > GitHub Apps
   - Click "New GitHub App"
   - Configure the app with these permissions:
     - Repository permissions: Actions, Administration, Checks, Contents (Read & write), Metadata (Read-only)
     - Organization permissions: Self-hosted runners (Read & write)
   - Generate and download a private key
   - Install the app on your account/organization
   - Note down the App ID and Installation ID

2. **Initialize and configure Terraform:**
   ```bash
   # Copy the example variables file
   cp terraform.tfvars.example terraform.tfvars
   
   # Edit the file to add your Civo API key
   nano terraform.tfvars
   ```

3. **Use the provided setup script:**
   ```bash
   # Make the script executable
   chmod +x setup.sh
   
   # Run the setup script
   ./setup.sh
   ```

   The script will:
   - Validate prerequisites
   - Ask for your GitHub App credentials
   - Create your Kubernetes cluster on Civo
   - Install cert-manager and Actions Runner Controller
   - Install Kubernetes Metrics Server for resource monitoring
   - Configure GitHub authentication
   - Set up runners for your repository or organization

## Customizing Your Deployment

You can customize your deployment by editing the following files:

- `terraform.tfvars`: Change cluster size, region, or other settings
- Variables passed to the setup script when prompted

## Cleaning Up

When you're done with the workshop, you can clean up all resources:

```bash
# Make the script executable
chmod +x cleanup.sh

# Run the cleanup script
./cleanup.sh
```

This will destroy all resources created by Terraform, preventing any further charges.

## Adding More Runners Later

If you need to add more runners or create runners for additional repositories:

```bash
# Navigate to the k8s directory
cd ../k8s

# Run the add-runners script
./add-runners.sh
```

This will prompt you for repository or organization details and create the necessary runner configurations.