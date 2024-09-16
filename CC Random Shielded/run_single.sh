#!/bin/bash

verifyta=${verifyta:-"$HOME/opt/uppaal-5.0.0-linux64/bin/verifyta.sh"}
RANDOM_FLEET=${RANDOM_FLEET:-"$PWD/Random Fleet.xml"}
RESULTS="$HOME/Results/N-player CC Random Shielded"
echo "Running single experiment."
# Create results dir if not exists
[ -d "$RESULTS" ] || mkdir "$RESULTS"

# Check if the first argument is "Safety"
if [ "${1}" = "Safety" ]; then
    $verifyta -s "$RANDOM_FLEET" "Safety.q" &> "$RESULTS/Safety.txt"

elif [ "${1}" = "Reward" ]; then
    $verifyta -s "$RANDOM_FLEET" "Reward.q" &> "$RESULTS/Reward.txt"
    
# Check if the first argument is a number
elif [[ "${1}" =~ ^[0-9]+$ ]]; then
    $verifyta -s "$RANDOM_FLEET" "D${1}.q" &> "$RESULTS/D${1}.txt"
    
else
    echo "First argument should be 'Safety', 'Reward' or a number 0-18"
fi
