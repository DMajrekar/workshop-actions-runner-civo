#!/bin/bash
# Mixed workload generator script

workload_type=$1
duration_mins=$2

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
  fi
fi

# Add randomness to duration (±20%)
random_factor=$(echo "scale=2; (0.8 + (0.4 * $RANDOM / 32767))" | bc)
actual_duration=$(echo "$duration_mins * $random_factor" | bc)
actual_duration=${actual_duration%.*}

# Ensure duration is at least 1 minute
if [ "$actual_duration" -lt 1 ]; then
  actual_duration=1
fi

# Calculate duration in seconds
duration_secs=$((actual_duration * 60))

# Install required tools if missing
install_tools() {
  echo "Checking and installing required tools..."
  
  if ! command -v stress-ng &> /dev/null; then
    echo "Installing stress-ng..."
    if command -v apt-get &> /dev/null; then
      sudo apt-get update
      sudo apt-get install -y stress-ng
    elif command -v yum &> /dev/null; then
      sudo yum install -y stress-ng
    else
      echo "Cannot install stress-ng, some workloads may not function correctly"
    fi
  fi
  
  if ! command -v fio &> /dev/null; then
    echo "Installing fio..."
    if command -v apt-get &> /dev/null; then
      sudo apt-get update
      sudo apt-get install -y fio
    elif command -v yum &> /dev/null; then
      sudo yum install -y fio
    else
      echo "Cannot install fio, IO workloads may not function correctly"
    fi
  fi
}

# CPU-intensive workload
run_cpu_workload() {
  local duration=$1
  echo "Running CPU-heavy workload for $duration seconds"
  
  if command -v stress-ng &> /dev/null; then
    timeout ${duration}s stress-ng --cpu 2 --cpu-method matrixprod --timeout ${duration}s || code=$?
    # Treat timeout exit code 124 as success
    if [ "${code:-0}" -eq 124 ]; then
      echo "CPU workload completed successfully after timeout"
    elif [ "${code:-0}" -ne 0 ]; then
      echo "CPU workload exited with code: ${code:-0}"
    fi
  else
    # Fallback to basic CPU load
    end_time=$(($(date +%s) + duration))
    while [ $(date +%s) -lt $end_time ]; do
      for i in {1..10000}; do echo "$i^2" | bc > /dev/null; done
      sleep 0.1
    done
  fi
}

# Memory-intensive workload
run_memory_workload() {
  local duration=$1
  echo "Running memory-heavy workload for $duration seconds"
  
  if command -v stress-ng &> /dev/null; then
    timeout ${duration}s stress-ng --vm 2 --vm-bytes 75% --timeout ${duration}s || code=$?
    # Treat timeout exit code 124 as success
    if [ "${code:-0}" -eq 124 ]; then
      echo "Memory workload completed successfully after timeout"
    elif [ "${code:-0}" -ne 0 ]; then
      echo "Memory workload exited with code: ${code:-0}"
    fi
  else
    # Fallback to basic memory usage
    end_time=$(($(date +%s) + duration))
    while [ $(date +%s) -lt $end_time ]; do
      # Create a large file in memory
      dd if=/dev/urandom of=/dev/shm/test_file bs=1M count=100
      sleep 1
      rm -f /dev/shm/test_file
      sleep 0.5
    done
  fi
}

# IO-intensive workload
run_io_workload() {
  local duration=$1
  echo "Running IO-heavy workload for $duration seconds"
  
  if command -v fio &> /dev/null; then
    # Create temporary file for IO operations
    TEMPFILE=$(mktemp)
    
    timeout ${duration}s fio --name=random-write --ioengine=posixaio --rw=randwrite --bs=4k --size=100m --numjobs=4 --runtime=${duration} --filename=${TEMPFILE} || code=$?
    # Treat timeout exit code 124 as success
    if [ "${code:-0}" -eq 124 ]; then
      echo "IO workload completed successfully after timeout"
    elif [ "${code:-0}" -ne 0 ]; then
      echo "IO workload exited with code: ${code:-0}"
    fi
    
    # Clean up
    rm -f ${TEMPFILE}
  else
    # Fallback to basic file operations
    end_time=$(($(date +%s) + duration))
    while [ $(date +%s) -lt $end_time ]; do
      dd if=/dev/urandom of=/tmp/test_file bs=8k count=1000
      sync
      rm -f /tmp/test_file
      sleep 0.5
    done
  fi
}

# Main execution
install_tools

case $workload_type in
  cpu-heavy)
    run_cpu_workload $duration_secs
    ;;
    
  memory-heavy)
    run_memory_workload $duration_secs
    ;;
    
  io-heavy)
    run_io_workload $duration_secs
    ;;
    
  mixed)
    echo "Running mixed workload for $actual_duration minutes"
    # Divide duration for each phase
    phase_duration=$((duration_secs / 3))
    
    echo "Phase 1: CPU-heavy workload"
    run_cpu_workload $phase_duration
    
    echo "Phase 2: Memory-heavy workload"
    run_memory_workload $phase_duration
    
    echo "Phase 3: IO-heavy workload"
    run_io_workload $phase_duration
    ;;
    
  *)
    echo "Unknown workload type: $workload_type"
    exit 1
    ;;
esac

echo "Workload completed"