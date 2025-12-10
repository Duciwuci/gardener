#!/usr/bin/env bash
#
# SPDX-FileCopyrightText: SAP SE or an SAP affiliate company and Gardener contributors
#
# SPDX-License-Identifier: Apache-2.0
#!/bin/bash

# --- Configuration ---
start=0
end=1
MAX_PARALLEL_JOBS=1
root_dir="$(dirname "${0}")/.."
shoot_template_file="$root_dir/development/shoot.yaml"
export KUBECONFIG=/etc/kube/garden/garden-config
# ---------------------

generate_random_string() {
  local length=$1
  local chars='a-z0-9'
  random_string=$(tr -dc "$chars" < /dev/urandom | fold -w $length | head -n 1)
  echo $random_string
}

parse_flags() {
  while test $# -gt 0; do
    case "$1" in
      --start)
        shift
        start="${1:-start}"
        ;;
      --end)
        shift
        end="${1:-end}"
        ;;
      *)
        echo "Unknown argument: $1"
        exit 1
        ;;
    esac
    shift
  done
}

parse_flags "$@"

## 🎯 Parallel Execution Loop ##

for (( i=$start; i<=$end; i++ ))
do
    # The actual work function
    apply_shoot() {
        local index=$1
        local hash=$(generate_random_string 6)
        local shoot_name="shoot-$hash"
        
        echo "Applying $shoot_name..."
        
        # Modify in memory (yq) and pipe to kubectl apply
        yq eval ".metadata.name = \"$shoot_name\"" "$shoot_template_file" | kubectl apply -f -
        
        # Check the exit status of the kubectl command
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to apply $shoot_name" >&2
        fi
    }

    # Run the function in the background (using '&')
    apply_shoot "$i" &

    # --- Job Control (The Key to Limiting Parallelism) ---
    
    # Get the number of currently running background jobs
    # This checks for jobs spawned by the current shell that are running.
    while [ $(jobs -r | wc -l) -ge $MAX_PARALLEL_JOBS ]; do
        # Wait for any single background job to finish
        sleep 0.1
        # The 'wait -n' command (available in Bash 4.3+) is more efficient:
        # wait -n
    done
    
done

# Wait for ALL remaining background jobs to finish before exiting the script
echo "Waiting for all background jobs to complete..."
wait

echo "--- Parallel application complete ($((end - start + 1)) shoots applied). ---"