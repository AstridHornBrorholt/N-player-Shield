#!/bin/bash

julia=${julia:-"$HOME/julia-1.9.2/bin/julia"}
log_output=${log_output:-"$(realpath "log.txt")"}
blueprint_path=${blueprint_path:-"$(realpath "Fleet_blueprint.xml")"}
results_dir="$HOME/Results/N-player CC Shield Transfer"
echo "Running single experiment. Saving logs to $log_output"
cd "../CC/"
$julia "Run Experiment.jl" --runs $runs --checks $checks --max-cars $max_cars --results-dir "$results_dir" --repetition $repetition --blueprint-path "$blueprint_path" &>> "$log_output"