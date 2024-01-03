#!/bin/bash
echo "Scheduling slurm jobs"

export log_output="$HOME/Results/N-player CP/log.txt"

date >> "$log_output"
ARGS="--out=/dev/null --exclude=rome0[1-3],dhabi0[1-3],naples0[1-3],vmware0[1-4] --partition=cpu -n1 --mem=4G --job-name CP"

repetitions=10

for ((r=1; r<=$repetitions; r++))
do
    export repetition=$r
    
    export runs=101
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export runs=2501
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export runs=5001
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export runs=10001
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export runs=20001
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
done