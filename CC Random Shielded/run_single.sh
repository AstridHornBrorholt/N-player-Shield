#!/bin/bash

verifyta=${verifyta:-"$HOME/opt/uppaal-5.1.0-beta5-linux64/bin/verifyta.sh"}
RESULTS="$HOME/Results/CC Random Shielded"
echo "Running single experiment."
[ -d "$RESULTS" ] || mkdir "$RESULTS"

# Check if the first argument is "Safety"
if [ "${1}" = "Safety" ]; then
    $verifyta -s "Random Fleet.xml" "Safety.q" &>> "$RESULTS/Safety.txt"
    
# Check if the first argument is a number
elif [[ "${1}" =~ ^[0-9]+$ ]]; then
    $verifyta -s "Random Fleet.xml" "D${1}.q" &>> "$RESULTS/D${1}.txt"
    
else
    echo "The first argument is neither 'Safety' nor a number"
fi
