#!/bin/bash

## Parameters ##

julia=${julia:-"/nfs/home/cs.aau.dk/oq82yk/julia-1.9.2/bin/julia"}
verifyta=${verifyta:-"/nfs/home/cs.aau.dk/oq82yk/uppaal-5.0.0-rc2-linux64/bin/verifyta.sh"}
results="$HOME/Results/N-player CC"
mkdir -p "$HOME/Results"
mkdir -p "$results"
mkdir -p "$results/Query Results"
shield="$results/libshield.so"
cp "$(pwd)/Shield/libshield.so" "$shield"
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
        echo "ⓘ $(date +%T) Running Fleet of ${N} Cars..."
        outfile="$results/Query Results/Fleet of $N Cars.txt"
        model_and_query=$($julia 'Create Fleet.jl' \
                --blueprint-path "$blueprint" \
                --strategy-paths "${strategies[@]}" \
                --shield-path "$shield" \
                --destination "$results" \
                --checks $checks )

        echo $model_and_query > "$log_output"

        # https://stackoverflow.com/a/21163341/10595676
        # eval to avoid model_and_query being interpretred as one single argument.
        eval $verifyta_call $model_and_query > "$outfile"
        strategies+=("$results/Models/car$((N-1)).json")
done