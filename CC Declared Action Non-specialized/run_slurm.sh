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

#sinfo -h -o %N >> dhabi[01-09],naples[01-09],rome[01-07],turing[01-02],vmware[01-04]
ARGS="--out=/dev/null --partition=dhabi -n1 --mem=16G --job-name $job_name"

export fleet_size=10
repetitions=10

min_runs=100
runs_step=100
max_runs=2000

for ((r=1; r<=$repetitions; r++)); do
    export repetition=$r

    for ((runs=$min_runs; runs<=$max_runs; runs+=$runs_step)); do
        export runs=$runs
        export checks=1000
        sbatch $ARGS ./run_single.sh
        echo "Job scheduled. (max_cars=$max_cars, checks=$checks, runs=$runs)"
    done
done