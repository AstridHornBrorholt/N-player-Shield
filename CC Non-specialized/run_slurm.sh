#!/bin/bash
echo "Scheduling slurm jobs"

export log_output="$HOME/Results/N-player CC Non-specialized/log.txt"

date >> "$log_output"

#sinfo -h -o %N >> dhabi[01-09],naples[01-09],rome[01-07],turing[01-02],vmware[01-04]
ARGS="--out=/dev/null --exclude=rome0[1-7],dhabi0[1-2],naples0[1-2],turing0[1-2] -n1 --mem=16G --job-name CCNonSpecialized"

export fleet_size=10
repetitions=10

for ((r=1; r<=$repetitions; r++))
do
    export repetition=$r
    
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