#!/bin/bash
echo "Scheduling slurm jobs"

export log_output="$HOME/Results/N-player CC Centralized Controller/log.txt"

date >> "$log_output"
ARGS="--out=/dev/null --exclude=rome0[1-3],dhabi0[1-3],naples0[1-3],vmware0[1-4] --partition=cpu -n1 --mem=16G --job-name 'CCCentralizedController'"

export max_cars=10
repetitions=10

for ((r=1; r<=$repetitions; r++))
do
    export repetition=$r
    export fleet_size=$max_cars

    # Yes the "runs" parameter is multiplied by fleet size.
    export runs=2500
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."

    export runs=5000
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."

    export runs=10000
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."

    export runs=20000
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
done