#!/bin/bash

## Parameters ##
runs=${1:-100}
checks=${2:-100}
max_cars=${3:-4}
results="$HOME/Results/N-player CC"
mkdir -p "$HOME/Results"
mkdir -p "$results"
mkdir -p "$results/Query Results"
shield="$results/libshield.so"
cp './Shield/libshield.so' "$shield"
blueprint="$(pwd)/Fleet_blueprint.xml"
strategies=()

verifyta_call='verifyta  -s
        --epsilon 0.001
        --max-iterations 1
        --good-runs $runs
        --total-runs $runs
        --runs-pr-state $runs'

for ((N=2; N<=$max_cars; N++))
do
    echo "ⓘ Running Fleet of ${N} Cars..."
    outfile="$results/Query Results/Fleet of $N Cars.txt"
    model_and_query=$(julia 'Create Fleet.jl' \
            --blueprint-path "$blueprint" \
            --strategy-paths "${strategies[@]}" \
            --shield-path "$shield" \
            --destination "$results" \
            --checks $checks )

    # https://stackoverflow.com/a/21163341/10595676
    # eval to avoid model_and_query being interpretred as one single argument.
    eval $verifyta_call $model_and_query > "$outfile"
    strategies+=("$results/Models/car$((N-1)).json")
done