#!/bin/bash
echo "Scheduling slurm jobs"

export log_output="$HOME/Results/N-player CC/log.txt"

date >> "$log_output"

#sinfo -h -o %N >> dhabi[01-09],naples[01-09],rome[01-07],turing[01-02],vmware[01-04]
ARGS="--out=/dev/null --exclude=dhabi[01-09],naples[01-09],turing[01-02],vmware[01-04] --partition=cpu -n1 --mem=16G --job-name CCNonSpecialized"

export max_cars=10
repetitions=10

for ((r=1; r<=$repetitions; r++))
do
    export repetition=$r
    
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
    
    export runs=$((2500*9))
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export runs=$((5000*9))
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export runs=$((10000*9))
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export runs=$((20000*9))
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
done