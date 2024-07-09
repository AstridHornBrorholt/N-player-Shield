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

ARGS="--out=/dev/null --partition=dhabi -n1 --mem=16G --job-name $job_name"

export max_cars=10
repetitions=5

for ((r=1; r<=$repetitions; r++))
do
    export repetition=$r
    
    export runs=2502
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export runs=5002
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
done