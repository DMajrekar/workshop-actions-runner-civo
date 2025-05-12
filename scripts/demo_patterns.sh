#!/bin/bash
# Demo patterns for autoscaling demonstration

pattern=$1
repo=$2

if [ -z "$pattern" ] || [ -z "$repo" ]; then
  echo "Usage: $0 <pattern> <repository>"
  echo "Patterns: steady-increase, sudden-burst, mixed-workload, scale-down-test"
  exit 1
fi

echo "Running demo pattern: $pattern for repository: $repo"

case "$pattern" in
  "steady-increase")
    echo "Demonstrating steady workload increase..."
    
    # Start with 2 jobs
    echo "Phase 1: Starting 2 concurrent jobs with 50% CPU load"
    gh workflow run cpu-load.yml -r $repo -f duration=5 -f concurrency=2 -f cpu_load=50
    
    # Wait a minute
    echo "Waiting 60 seconds before next phase..."
    sleep 60
    
    # Add 3 more jobs
    echo "Phase 2: Starting 3 more concurrent jobs with 60% CPU load"
    gh workflow run cpu-load.yml -r $repo -f duration=7 -f concurrency=3 -f cpu_load=60
    
    # Wait a minute
    echo "Waiting 60 seconds before next phase..."
    sleep 60
    
    # Add mixed workloads
    echo "Phase 3: Adding mixed workload types"
    gh workflow run mixed-workload.yml -r $repo -f workflow_type=mixed -f duration=8
    gh workflow run mixed-workload.yml -r $repo -f workflow_type=cpu-heavy -f duration=6
    gh workflow run mixed-workload.yml -r $repo -f workflow_type=memory-heavy -f duration=7
    gh workflow run mixed-workload.yml -r $repo -f workflow_type=io-heavy -f duration=5
    ;;
    
  "sudden-burst")
    echo "Demonstrating sudden job burst..."
    
    # Queue many short jobs
    echo "Queuing 25 short-running jobs"
    gh workflow run burst-jobs.yml -r $repo -f job_count=25 -f duration=2
    ;;
    
  "mixed-workload")
    echo "Demonstrating multi-type concurrent workloads..."
    
    # Trigger jobs from different workflows simultaneously
    echo "Starting CPU-intensive jobs"
    gh workflow run cpu-load.yml -r $repo -f duration=8 -f concurrency=4 -f cpu_load=70
    
    echo "Starting burst jobs"
    gh workflow run burst-jobs.yml -r $repo -f job_count=10 -f duration=3
    
    echo "Starting mixed workload jobs"
    gh workflow run mixed-workload.yml -r $repo -f workflow_type=mixed -f duration=7
    gh workflow run mixed-workload.yml -r $repo -f workflow_type=cpu-heavy -f duration=5
    ;;
    
  "scale-down-test")
    echo "Demonstrating scale-down behavior..."
    
    # First create heavy load
    echo "Phase 1: Creating initial heavy load"
    gh workflow run cpu-load.yml -r $repo -f duration=3 -f concurrency=6 -f cpu_load=80
    gh workflow run burst-jobs.yml -r $repo -f job_count=8 -f duration=2
    
    echo "Load created, waiting for scale-up (3 minutes)..."
    sleep 180
    
    echo "Phase 2: Now watching scale-down behavior as jobs complete..."
    echo "No more jobs will be triggered, allowing the system to scale down"
    ;;
    
  *)
    echo "Unknown pattern: $pattern"
    echo "Available patterns: steady-increase, sudden-burst, mixed-workload, scale-down-test"
    exit 1
    ;;
esac

echo "Demo pattern triggered. Monitor your Kubernetes cluster to observe scaling behavior."