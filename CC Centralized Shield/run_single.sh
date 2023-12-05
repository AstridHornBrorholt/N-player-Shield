#!/bin/bash

julia=${julia:-"$HOME/julia-1.9.2/bin/julia"}
log_output=${log_output:-"log.txt"}
echo "Running single experiment. Saving logs to $(realpath "$log_output")"
$julia "Run Experiment.jl" --runs $runs --checks $checks --repetition $repetition --blueprint-path "$blueprint_path" --shield-path "$shield_path" &>> "$log_output"