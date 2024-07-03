#!/bin/bash

julia=${julia:-"$HOME/julia-1.10.4/bin/julia"}
log_output=${log_output:-"log.txt"}
echo "Running single experiment. Saving logs to $(realpath "$log_output")"
$julia "Run Experiment.jl" --runs $runs --checks $checks --fleet-size $fleet_size --repetition $repetition &>> "$log_output"