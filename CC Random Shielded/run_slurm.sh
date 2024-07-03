#!/bin/bash
echo "Scheduling slurm jobs"

RESULTS="$HOME/Results/N-player CC Random Shielded"
[ -d "$RESULTS" ] || mkdir "$RESULTS"
export log_output="$RESULTS/log.txt"

date >> "$log_output"
ARGS="--out=/dev/null --partition=rome -n1 --mem=16G --job-name 'CCRandomShielded'"

# Make a copy of the thing. The uppaal file.
export RANDOM_FLEET="$RESULTS/Random Fleet.xml"
# Put in correct shield.
export SHIELD="$RESULTS/libshield.so"
cp "../CC Shield/libshield.so" "$SHIELD"
sed "s#/home/asger/Documents/Files/Arbejde/AAU/Artikler/N-player Shield/CC Shield/libshield.so#$SHIELD#" "Random Fleet.xml" > "$RANDOM_FLEET"

# Schedule slurm jobs
for ((i=0; i<=9; i++))
do
    sbatch $ARGS ./run_single.sh $i
    echo "Job scheduled."
done
sbatch $ARGS ./run_single.sh Reward
sbatch $ARGS ./run_single.sh Safety
echo "Job scheduled."