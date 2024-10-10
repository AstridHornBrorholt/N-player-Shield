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

ARGS="--out=/dev/null --partition=dhabi -n1 --mem=20G --job-name $job_name"

repetitions=10

min_runs=6000
runs_step=6000
max_runs=60000

for ((r=1; r<=$repetitions; r++)); do
    export repetition=$r
    
    for ((runs=$min_runs; runs<=$max_runs; runs+=$runs_step)); do
        export runs=$runs
        export checks=1000
        sbatch $ARGS ./run_single.sh
        echo "Job scheduled."
    done
done