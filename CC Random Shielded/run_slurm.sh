#!/bin/bash
echo "Scheduling slurm jobs"

RESULTS="$HOME/Results/CC Random Shielded"
[ -d "$RESULTS" ] || mkdir "$RESULTS"
export log_output="$RESULTS/log.txt"

date >> "$log_output"
ARGS="--out=/dev/null --exclude=rome0[1-3],dhabi0[1-3],naples0[1-3],vmware0[1-4] --partition=cpu -n1 --mem=16G --job-name StdCC"

# Make a copy of the thing. The uppaal file.
export RANDOM_FLEET="$RESULTS/Random Fleet.xml"
# Put in correct shield.
export SHIELD="$RESULTS/libshield.so"
cp "../CC Shield/libshield.so" "$SHIELD"
sed "s#/home/asger/Documents/Files/Arbejde/AAU/Artikler/N-player Shield/CC Shield/libshield.so#$SHIELD#" "Random Fleet.xml" > "$RANDOM_FLEET"

# Schedule slurm jobs
for ((i=0; i<=19; i++))
do
    sbatch $ARGS ./run_single.sh $i
    echo "Job scheduled."
done
sbatch $ARGS ./run_single.sh Safety
echo "Job scheduled."