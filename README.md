# GitHub Actions Runners on Civo Kubernetes Workshop

This workshop demonstrates how to set up, configure, and optimize GitHub Actions self-hosted runners on Civo's managed Kubernetes platform using [Actions Runner Controller (ARC)](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/about-actions-runner-controller). It combines the power of Kubernetes with the flexibility of GitHub Actions to create a scalable, cost-effective CI/CD infrastructure.

## Workshop Hands-On

1. **Sign up for a Civo Account**
   - Create an account at [civo.com](https://www.civo.com)
   - Get your API key from the [Civo dashboard](https://dashboard.civo.com/security)

2. **Install Required Tools**
   - [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes command-line tool
   - [terraform](https://www.terraform.io/downloads.html) - Infrastructure as Code tool
   - [Civo CLI](https://github.com/civo/cli) - Command-line interface for Civo

3. **Civo CLI Setup with API Key**
   ```bash
   civo apikey add default YOUR_API_KEY
   ```
   - Run a list regions command to verify
   ```bash
   civo region ls
   ```
   - Use the PHX1 region for this workshop
   ```bash
   civo region use PHX1
   ```

4. **Create git repo in your GitHub Account**
   - Create a new repository in GitHub
   - Clone the workshop repository to use as a template

5. **Checkout code locally**
   ```bash
   git clone https://github.com/your-username/your-repo.git
   cd your-repo
   ```

6. **Create GitHub Personal Access Token (PAT)**
   1. Go to GitHub Settings > Developer settings > Personal access tokens > Tokens (classic)
   2. Click "Generate new token" > "Generate new token (classic)"
   3. Configure the token:
      - Name: "Actions Runner Controller Workshop"
      - Expiration: Set an appropriate expiration (e.g., 7 days)
      - Scopes: Select `repo` (Full control of private repositories)
   4. Click "Generate token"
   5. Copy and save your token immediately

7. **Run terraform/setup.sh**
   ```bash
   cd terraform
   chmod +x setup.sh
   ./setup.sh
   ```
   - When prompted, enter your GitHub Personal Access Token
   - The script will provision the infrastructure and configure everything

8. **Check runner is attached to your repo**
   - Go to your GitHub repo > Settings > Actions > Runners
   - Verify the runner appears in the list

9. **Run single process job**
   - Use the provided script to trigger a single job process:
   ```bash
   cd /projects/workshop
   chmod +x scripts/trigger_single_job.sh
   ./scripts/trigger_single_job.sh <your-github-username> <your-repo-name>
   
   # Example:
   # ./scripts/trigger_single_job.sh janedoe my-workshop-repo
   ```
   
   Note: This script always uses the "main" branch to trigger workflows.
   
   This script will trigger a job that runs for 5 minutes using your self-hosted runner.
   - Alternatively, you can manually trigger the workflow from the GitHub UI:
     - Go to the Actions tab in your GitHub repository
     - Select the "Process Single Job" workflow
     - Click "Run workflow"
   - Monitor your runner in the Kubernetes cluster:
   ```bash
   kubectl get pods -n actions-runner-system -w
   ```

10. **Run scaling test**
    - Try different workload patterns using the demo script:
    ```bash
    # Navigate to your repository
    cd /projects/workshop
    # Run a pattern, e.g., sudden-burst
    ./scripts/demo_patterns.sh sudden-burst your-username/your-repo main
    ```
    
    The script parameters are:
    ```
    ./scripts/demo_patterns.sh <pattern> <repository> [branch]
    ```
    
    Where:
    - `<pattern>`: One of: sudden-burst, steady-increase, mixed-workload, scale-down-test
    - `<repository>`: Your full repository path (username/repo-name)
    - `[branch]`: Optional branch name, defaults to "main" if not specified
    
    Example:
    ```bash
    ./scripts/demo_patterns.sh sudden-burst janedoe/workshop-actions-runner main
    ```
    - Monitor the Kubernetes pods as they scale up:
    ```bash
    kubectl get pods -n actions-runner-system -w
    ```
    - Observe node autoscaler activity:
    ```bash
    kubectl logs -n kube-system deployment/cluster-autoscaler
    ```
    - Watch nodes being added to your cluster:
    ```bash
    kubectl get nodes -w
    ```

## Technical Components

### Kubernetes Metrics Server

The [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server) collects resource metrics from Kubelets and exposes them through the Kubernetes API server for use by:

- Horizontal Pod Autoscaler for scaling workloads
- Vertical Pod Autoscaler for right-sizing container resources
- kubectl top commands for easy resource monitoring

### Actions Runner Controller (ARC)

This workshop uses [Actions Runner Controller (ARC)](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/about-actions-runner-controller), GitHub's official Kubernetes-based controller for managing self-hosted runners. Key ARC features include:

- Automatic scaling of runners based on workflow demands
- Management of runner lifecycles
- Support for both repository and organization-level runners
- Kubernetes-native management with custom resources

### Civo Kubernetes

- Fast provisioning (under 90 seconds)
- Free control plane with cost-effective worker nodes
- No data transfer costs, unlike other cloud providers

### Terraform Automation

- One-command cluster provisioning with proper security
- Consistent, reproducible infrastructure
- Easy cleanup to prevent lingering costs

### Civo Cluster Autoscaler

- Automatic scaling of Kubernetes nodes based on workload demand
- Customizable scaling range (min and max nodes) via Terraform variables
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

## Monitoring and Troubleshooting

### Using the Metrics Server

1. Check node CPU and memory usage:
   ```bash
   kubectl top nodes
   ```

2. Check pod resource consumption:
   ```bash
   kubectl top pods -A
   ```

3. Monitor runner pod resource usage:
   ```bash
   kubectl top pods -n actions-runner-system
   ```

### Troubleshooting

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

## Cleaning Up

When you're done with the workshop, clean up your resources:

```bash
cd terraform
./cleanup.sh
```

This will destroy all resources created by Terraform, including the Kubernetes cluster and all associated resources.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [Civo](https://www.civo.com) for providing the Kubernetes platform
- [Actions Runner Controller (ARC)](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners-with-actions-runner-controller/about-actions-runner-controller) - GitHub's official Kubernetes controller for self-hosted runners
- [ARC GitHub Repository](https://github.com/actions/actions-runner-controller) for the open source project
- [Kubernetes Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) project
- [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server) for resource monitoring
