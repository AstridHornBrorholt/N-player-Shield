#!/bin/bash
echo "Scheduling slurm jobs"

export log_output="$HOME/Results/N-player CP Centralized Controller/log.txt"

date >> "$log_output"
ARGS="--out=/dev/null --exclude=rome0[1-3],dhabi0[1-3],naples0[1-3],vmware0[1-4] -n1 --mem=20G --job-name 'CPCentralizedController'"

repetitions=10

export repetition=3
export runs=1000
export checks=1000
sbatch $ARGS ./run_single.sh
echo "Job scheduled."

export repetition=7
export runs=1000
export checks=1000
sbatch $ARGS ./run_single.sh
echo "Job scheduled."


export repetition=4
export runs=10000
export checks=1000
sbatch $ARGS ./run_single.sh
echo "Job scheduled."

export repetition=0
export runs=20000
export checks=1000
sbatch $ARGS ./run_single.sh
echo "Job scheduled."