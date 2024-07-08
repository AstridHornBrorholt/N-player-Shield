#!/bin/bash

export experiment_name=$(basename "$(pwd)")
export results_dir="$HOME/Results/N-player $experiment_name"

[ -d "$results_dir" ] || mkdir -p "$results_dir"
export log_output="$results_dir/log.txt"

echo "
==================================
New batch of slurm-jobs scheduled.
$(date)
" >> "$log_output"

echo "Scheduling slurm jobs. Writing logs to \"$log_output\""

ARGS="--out=/dev/null --partition=rome -n1 --mem=16G --job-name 'CCCentralizedController'"

export max_cars=10
repetitions=10

for ((r=1; r<=$repetitions; r++))
do
    export repetition=$r
    export fleet_size=$max_cars

    # Yes the "runs" parameter is multiplied by fleet size.
    export runs=500
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."

    export runs=1000
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."

    export runs=1500
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."

    export runs=2000
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."

    export runs=2500
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."

    export runs=3000
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
done