#!/bin/bash

## Parameters ##

julia=${julia:-"$HOME/julia-1.9.2/bin/julia"}

$julia "Run Experiment.jl" --runs $runs --checks $checks --max-cars $max_cars