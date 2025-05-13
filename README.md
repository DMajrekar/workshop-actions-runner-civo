# GitHub Actions Runners on Civo Kubernetes Workshop

This workshop demonstrates how to set up, configure, and optimize GitHub Actions self-hosted runners on Civo's managed Kubernetes platform using [Actions Runner Controller (ARC)](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/about-actions-runner-controller). It combines the power of kubernetes with the flexibility of GitHub Actions to create a scalable, cost-effective CI/CD infrastructure.

## Key Features

- **Auto-scaling GitHub Actions Runners**: Dynamically scale runners based on workflow demand
- **Infrastructure as Code**: Provision Kubernetes clusters on Civo using Terraform
- **Cost Optimization**: Save 40-70% compared to GitHub-hosted runners with more control
- **Multi-Project Support**: Configure runners for multiple repositories or organizations
- **Real-world Testing**: Simulate various workflow patterns to demonstrate scaling
- **Cluster Autoscaling**: Automatic scaling of Kubernetes nodes based on workload demand

## Technical Components

### Actions Runner Controller (ARC)

This workshop uses [Actions Runner Controller (ARC)](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/about-actions-runner-controller), GitHub's official Kubernetes-based controller for managing self-hosted runners. Key ARC features include:

- Automatic scaling of runners based on workflow demands
- Management of runner lifecycles
- Support for both repository and organization-level runners
- Kubernetes-native management with custom resources

For more details on ARC concepts and components, refer to the [official documentation](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/about-actions-runner-controller).

### Civo Kubernetes

- Lightweight K3s cluster with fast provisioning (under 90 seconds)
- Free control plane with cost-effective worker nodes
- No data transfer costs, unlike other cloud providers

### Terraform Automation

- One-command cluster provisioning with proper security
- Consistent, reproducible infrastructure
- Easy cleanup to prevent lingering costs

### Civo Cluster Autoscaler

- Automatic scaling of Kubernetes nodes based on workload demand
- Seamless integration with Civo's managed Kubernetes service
- Integrated with Terraform for one-command deployment

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
- [Civo CLI](https://github.com/civo/cli) configured with your API key

## Workshop Guide

### Part 1: Civo Account Setup

1. If you don't have a Civo account, sign up at [civo.com](https://www.civo.com)
2. Get your API key from the [Civo dashboard](https://dashboard.civo.com/security)
3. Configure the Civo CLI with your API key:
   ```bash
   civo apikey add default YOUR_API_KEY
   ```

Notes:
- The Civo API key is used by the Terraform provider to create resources
- Civo automatically creates a `civo-api-access` secret with necessary credentials for the cluster autoscaler

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

2. Copy the example variables file and edit it with your preferences
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   nano terraform.tfvars  # Edit with your preferences
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
   - Install and configure the Civo Cluster Autoscaler

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

2. Observe runner autoscaling metrics:
   ```bash
   kubectl describe horizontalrunnerautoscaler -n actions-runner-system
   ```

3. Monitor node autoscaler activity:
   ```bash
   kubectl get pods -n kube-system | grep cluster-autoscaler
   kubectl logs -n kube-system deployment/cluster-autoscaler
   ```

4. Watch nodes being added to your cluster:
   ```bash
   kubectl get nodes -w
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

   Add or modify the resources section to set CPU and memory requests/limits:
   ```yaml
   spec:
     template:
       spec:
         resources:
           limits:
             cpu: "1000m"
             memory: "2Gi"
           requests:
             cpu: "500m"
             memory: "1Gi"
   ```

3. Configure the cluster autoscaler:
   ```bash
   kubectl edit deployment -n kube-system cluster-autoscaler
   ```

   Modify the command arguments to change min/max nodes or other parameters:
   ```yaml
   command:
     - ./cluster-autoscaler
     - --v=4
     - --stderrthreshold=info
     - --cloud-provider=civo
     - --nodes=3:10:workers  # Change min:max:pool-name as needed
     - --scale-down-delay-after-add=10m  # Adjust scale-down delay
   ```

   Setting these configurations ensures:
   - Pods will remain unscheduled until sufficient resources are available
   - The Civo node autoscaler can trigger node creation before scheduling pods
   - Better resource allocation across your cluster
   - Efficient scaling based on your workflow patterns

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

3. Check cluster autoscaler logs:
   ```bash
   kubectl logs -n kube-system deployment/cluster-autoscaler
   ```

4. Verify your GitHub Personal Access Token's scopes and expiration
5. Ensure your Civo API key has sufficient permissions
6. Make sure the Civo node autoscaler is properly installed and configured for your cluster. Without it, pods may remain in `Pending` state even with proper resource requirements.
7. Refer to the [official ARC troubleshooting guide](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/troubleshooting-actions-runner-controller) for more detailed help

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
- [Actions Runner Controller (ARC)](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/about-actions-runner-controller) - GitHub's official Kubernetes controller for self-hosted runners
- [ARC GitHub Repository](https://github.com/actions/actions-runner-controller) for the open source project
- [Kubernetes Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) project
- [Civo Cluster Autoscaler](https://github.com/civo/cluster-autoscaler) for Civo integration
