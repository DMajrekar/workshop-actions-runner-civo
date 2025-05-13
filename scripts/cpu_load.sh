#!/bin/bash
# CPU load generator script

# Get parameters
duration_mins=$1
cpu_percentage=$2

# Ensure bc is installed
if ! command -v bc &> /dev/null; then
  echo "Installing bc..."
  if command -v apt-get &> /dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y bc
  elif command -v yum &> /dev/null; then
    sudo yum install -y bc
  else
    echo "Cannot install bc, using default duration without randomization"
    actual_duration=$duration_mins
    variation=0
  fi
fi

# Add some randomness to duration (±20%)
variation=$(echo "scale=2; $duration_mins * 0.4 * $(echo "scale=4; $RANDOM/32767" | bc)" | bc)
if [ $((RANDOM % 2)) -eq 0 ]; then
  actual_duration=$(echo "$duration_mins + $variation" | bc)
else
  actual_duration=$(echo "$duration_mins - $variation" | bc)
fi

# Ensure duration is positive
actual_duration=$(echo "$actual_duration" | awk '{print ($1 > 0) ? $1 : 1}')

# Calculate end time
end_time=$(($(date +%s) + ${actual_duration%.*} * 60))

# Get number of CPU cores
cores=$(nproc)

# Calculate load per core
load_per_core=$(echo "scale=2; $cpu_percentage / 100" | bc)

echo "Running CPU load of ${cpu_percentage}% for ${actual_duration%.*} minutes"

# Install stress-ng if not available
if ! command -v stress-ng &> /dev/null; then
  echo "Installing stress-ng..."
  if command -v apt-get &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y stress-ng
  elif command -v yum &> /dev/null; then
    sudo yum install -y stress-ng
  else
    echo "Cannot install stress-ng, falling back to CPU-intensive loop"
    # Run CPU load using fallback method
    while [ $(date +%s) -lt $end_time ]; do
      for i in $(seq 1 $cores); do
        # Start background process with CPU intensive task
        awk 'BEGIN{for(i=0;i<1000000;i++)for(j=0;j<1000;j++);print "done"}' &
      done
      sleep 1
      # Kill all awk processes to control CPU usage
      pkill awk
      sleep $((10 - cores * load_per_core))
    done
    exit 0
  fi
fi

# Run CPU load until end time
while [ $(date +%s) -lt $end_time ]; do
  # Generate CPU load using stress-ng
  stress-ng --cpu $cores --cpu-load $load_per_core --timeout 30s
  sleep 2
done

echo "CPU load test completed"