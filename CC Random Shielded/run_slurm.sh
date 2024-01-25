#!/bin/bash
echo "Scheduling slurm jobs"

RESULTS="$HOME/Results/CC Random Shielded"
[ -d "$RESULTS" ] || mkdir "$RESULTS"
export log_output="$RESULTS/log.txt"

date >> "$log_output"
ARGS="--out=/dev/null --exclude=rome0[1-3],dhabi0[1-3],naples0[1-3],vmware0[1-4] --partition=cpu -n1 --mem=16G --job-name StdCC"

for ((i=0; i<=19; i++))
do
    sbatch $ARGS ./run_single.sh $i
    echo "Job scheduled."
done


sbatch $ARGS ./run_single.sh Safety
echo "Job scheduled."