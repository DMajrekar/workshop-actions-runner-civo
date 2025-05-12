# GitHub Actions Runners on Civo Kubernetes Workshop

This workshop demonstrates how to set up, configure, and optimize GitHub Actions self-hosted runners on Civo's managed Kubernetes platform. It combines the power of kubernetes with the flexibility of GitHub Actions to create a scalable, cost-effective CI/CD infrastructure.

## Key Features

- **Auto-scaling GitHub Actions Runners**: Dynamically scale runners based on workflow demand
- **Infrastructure as Code**: Provision Kubernetes clusters on Civo using Terraform
- **Cost Optimization**: Save 40-70% compared to GitHub-hosted runners with more control
- **Multi-Project Support**: Configure runners for multiple repositories or organizations
- **Real-world Testing**: Simulate various workflow patterns to demonstrate scaling

## Repository Structure

```
/
├── .github/workflows/  # Example GitHub Actions workflows to test runners
├── scripts/            # Utility scripts for generating workloads
├── terraform/          # Infrastructure as Code for provisioning the cluster
└── README.md           # Workshop documentation
```

## Prerequisites

- A GitHub account
- A Civo account ([sign up here](https://www.civo.com/))
- Basic familiarity with Kubernetes and Terraform
- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)

## Workshop Guide

### Part 1: Civo Account Setup

1. If you don't have a Civo account, sign up at [civo.com](https://www.civo.com)
2. Get your API key from the [Civo dashboard](https://dashboard.civo.com/security)
3. Make note of your API key for later use

### Part 2: Creating a GitHub Personal Access Token (PAT)

For runner authentication with GitHub, you'll need to create a Personal Access Token:

1. Go to GitHub Settings > Developer settings > Personal access tokens > Tokens (classic)
2. Click "Generate new token" > "Generate new token (classic)"
3. Configure the token:
   - Name: "Actions Runner Controller Workshop"
   - Expiration: Set an appropriate expiration (e.g., 7 days)
   - Scopes:
     - For repository runners: Select `repo` (Full control of private repositories)
     - For organization runners: Select `admin:org` (with `write:org` scope)
4. Click "Generate token"
5. Copy and save your token immediately (you won't be able to see it again)

### Part 3: Provisioning Infrastructure with Terraform

1. Navigate to the `terraform` directory
   ```bash
   cd terraform
   ```

2. Copy the example variables file and edit it with your Civo API key
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   nano terraform.tfvars  # Edit with your Civo API key and preferences
   ```

3. Run the setup script to provision the infrastructure
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

4. When prompted, enter your GitHub Personal Access Token

5. The setup will:
   - Create a Kubernetes cluster on Civo
   - Install cert-manager and Actions Runner Controller
   - Configure GitHub authentication
   - Set up repository or organization runners

## Testing Your Runners

### Verify Runner Registration

1. Verify that your runners appear in GitHub
   - For repository runners: Go to your repo > Settings > Actions > Runners
   - For organization runners: Go to your org > Settings > Actions > Runners

### Run Sample Workflows

1. Go to the Actions tab in your GitHub repository
2. You'll see several workflows available:
   - CPU Load Test
   - Queue Burst Test
   - Mixed Workload
   - Demo Controller
3. Try running a CPU Load Test:
   ```bash
   # Trigger the CPU load workflow
   cd /projects/workshop
   git add .
   git commit -m "Test runners"
   git push
   ```

4. Monitor your runners in the Kubernetes cluster:
   ```bash
   kubectl get pods -n actions-runner-system -w
   ```

### Experiment with Different Patterns

Try different workload patterns using the demo script:

```bash
# Navigate to your repository
cd /projects/workshop
# Run a pattern, e.g., sudden-burst
./scripts/demo_patterns.sh sudden-burst your-username/your-repo
```

Available patterns:
- **steady-increase**: Gradually adds more jobs to demonstrate smooth scaling
- **sudden-burst**: Creates many jobs at once to test rapid scaling
- **mixed-workload**: Runs different types of jobs simultaneously
- **scale-down**: Creates workloads and then lets them complete to show scale-down behavior

### Understanding Autoscaling

1. Monitor the Kubernetes pods as they scale up:
   ```bash
   kubectl get pods -n actions-runner-system -w
   ```

2. Observe autoscaling metrics:
   ```bash
   kubectl describe horizontalrunnerautoscaler -n actions-runner-system
   ```

## Customizing Your Setup

1. Modify runner scaling parameters:
   ```bash
   kubectl edit horizontalrunnerautoscaler -n actions-runner-system github-runner-autoscaler
   ```

2. Adjust the resource limits for your runners:
   ```bash
   kubectl edit runnerdeployment -n actions-runner-system github-runner
   ```

## Cleaning Up

When you're done with the workshop, clean up your resources:

```bash
cd terraform
./cleanup.sh
```

This will destroy all resources created by Terraform, including the Kubernetes cluster and all associated resources.

## Troubleshooting

If you encounter issues:

1. Check controller logs:
   ```bash
   kubectl logs -n actions-runner-system deployment/actions-runner-controller-actions-runner-controller
   ```

2. Check runner pod logs:
   ```bash
   kubectl logs -n actions-runner-system pod/github-runner-xxxxx
   ```

3. Verify your GitHub Personal Access Token's scopes and expiration
4. Ensure your Civo API key has sufficient permissions

## Why Civo K3s?

- **Speed**: Clusters deploy in under 90 seconds
- **Simplicity**: K3s is lightweight and easier to manage than full Kubernetes
- **Cost Efficiency**: No control plane charges and competitive node pricing
- **Free Data Transfer**: No egress charges, unlike other cloud providers
- **Developer Experience**: Clean dashboard and simple CLI tools

## Benefits for Users

- **Cost Savings**: Save 40-70% compared to GitHub-hosted runners
- **Increased Control**: Custom environment, tools, and resource allocation
- **Better Performance**: Faster builds with optimized hardware configurations
- **Improved Security**: Runners in your own infrastructure with controlled access
- **Scalability**: Handle peak loads without maintaining idle capacity
- **Multi-project Efficiency**: Share runner infrastructure across repositories or teams

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [Civo](https://www.civo.com) for providing the K3s platform
- [Actions Runner Controller](https://github.com/actions-runner-controller/actions-runner-controller) project
