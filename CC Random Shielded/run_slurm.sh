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

ARGS="--out=/dev/null --partition=dhabi -n1 --mem=16G --job-name $job_name"

# Make a copy of the thing. The uppaal file.
export RANDOM_FLEET="$results_dir/Random Fleet.xml"
# Put in correct shield.
export SHIELD="$results_dir/libshield.so"
cp "../CC Shield/libshield.so" "$SHIELD"
sed "s#/home/asger/Documents/Files/AAU/PhD/Artikler/Multi-agent Shielding/N-player Experiments/CC Shield/libshield.so#$SHIELD#" "Random Fleet.xml" > "$RANDOM_FLEET"

# Schedule slurm jobs
for ((i=0; i<=9; i++)); do
    sbatch $ARGS ./run_single.sh $i
    echo "Job scheduled."
done
sbatch $ARGS ./run_single.sh Reward
sbatch $ARGS ./run_single.sh Safety
echo "Job scheduled."