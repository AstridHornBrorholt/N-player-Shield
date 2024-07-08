#!/bin/bash

export experiment_name=$(basename "$(pwd)")
export results_dir="$HOME/Results/N-player $experiment_name"
job_name=$(echo -e "${experiment_name}" | tr -d '[:space:]')

[ -d "$results_dir" ] || mkdir -p "$results_dir"
export log_output="$results_dir/log.txt"

echo "
==================================
New batch of slurm-jobs scheduled.
$(date)
" >> "$log_output"

echo "Scheduling slurm jobs. Writing logs to \"$log_output\""

ARGS="--out=/dev/null --partition=rome -n1 --mem=20G --job-name $job_name"

repetitions=10

export repetition=3
export runs=1000
export checks=1000
sbatch $ARGS ./run_single.sh
echo "Job scheduled."

export repetition=7
export runs=1000
export checks=1000
sbatch $ARGS ./run_single.sh
echo "Job scheduled."


export repetition=4
export runs=10000
export checks=1000
sbatch $ARGS ./run_single.sh
echo "Job scheduled."

export repetition=0
export runs=20000
export checks=1000
sbatch $ARGS ./run_single.sh
echo "Job scheduled."