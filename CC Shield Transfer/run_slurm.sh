#!/bin/bash
echo "Scheduling slurm jobs"

export log_output="$HOME/Results/N-player CC Shield Transfer/log.txt"

date >> "$log_output"
ARGS="--out=/dev/null --exclude=rome0[1-3],dhabi0[1-3],naples0[1-3],vmware0[1-4] --partition=cpu -n1 --mem=16G --job-name 'CC Shield Transfer'"

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