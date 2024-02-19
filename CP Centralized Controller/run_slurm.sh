#!/bin/bash
echo "Scheduling slurm jobs"

export log_output="$HOME/Results/N-player CP Centralized Controller/log.txt"

date >> "$log_output"
ARGS="--out=/dev/null --exclude=rome0[1-3],dhabi0[1-3],naples0[1-3],vmware0[1-4] --partition=cpu -n1 --mem=20G --job-name 'CPCentralizedController'"

repetitions=10

for ((r=1; r<=$repetitions; r++))
do
    export repetition=$r
    
    export runs=1000
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export runs=25000
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export runs=50000
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export runs=100000
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export runs=200000
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
done