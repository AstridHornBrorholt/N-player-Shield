#!/bin/bash

export experiment_name=$(basename "$(pwd)")
export results_dir="$HOME/Results/N-player $experiment_name"
job_name=$(echo -e "${experiment_name}" | tr -d '[:space:]')

[ -d "$results_dir" ] || mkdir -p "$results_dir"
export log_output="$results_dir/log.txt"

echo "
==================================
New batch of slurm-jobs scheduled.
$(date)
" >> "$log_output"

echo "Scheduling slurm jobs. Writing logs to \"$log_output\""

ARGS="--out=/dev/null --partition=rome -n1 --mem=4G --job-name $job_name"

repetitions=10

for ((r=1; r<=$repetitions; r++))
do
    export repetition=$r
    
    # export blueprint_path="$(pwd)/3-Car Centralized_blueprint.xml"
    # export shield_path="$(pwd)/3-car.so"
    # export runs=2500
    # export checks=1000
    # sbatch $ARGS ./run_single.sh
    # echo "Job scheduled."

    # export blueprint_path="$(pwd)/3-Car Centralized_blueprint.xml"
    # export shield_path="$(pwd)/3-car.so"
    # export runs=5000
    # export checks=1000
    # sbatch $ARGS ./run_single.sh
    # echo "Job scheduled."
    
    # export blueprint_path="$(pwd)/3-Car Centralized_blueprint.xml"
    # export shield_path="$(pwd)/3-car.so"
    # export runs=10000
    # export checks=1000
    # sbatch $ARGS ./run_single.sh
    # echo "Job scheduled."
    
    # export blueprint_path="$(pwd)/3-Car Centralized_blueprint.xml"
    # export shield_path="$(pwd)/3-car.so"
    # export runs=20000
    # export checks=1000
    # sbatch $ARGS ./run_single.sh
    # echo "Job scheduled."

    # export blueprint_path="$(pwd)/3-Car_blueprint.xml"
    # export shield_path="$(pwd)/2-car.so"
    # export runs=2500
    # export checks=1000
    # sbatch $ARGS ./run_single.sh
    # echo "Job scheduled."

    # export blueprint_path="$(pwd)/3-Car_blueprint.xml"
    # export shield_path="$(pwd)/2-car.so"
    # export runs=5000
    # export checks=1000
    # sbatch $ARGS ./run_single.sh
    # echo "Job scheduled."
    
    # export blueprint_path="$(pwd)/3-Car_blueprint.xml"
    # export shield_path="$(pwd)/2-car.so"
    # export runs=10000
    # export checks=1000
    # sbatch $ARGS ./run_single.sh
    # echo "Job scheduled."
    
    # export blueprint_path="$(pwd)/3-Car_blueprint.xml"
    # export shield_path="$(pwd)/2-car.so"
    # export runs=20000
    # export checks=1000
    # sbatch $ARGS ./run_single.sh
    # echo "Job scheduled."

    export blueprint_path="$(pwd)/3-Car Declared Action_blueprint.xml"
    export shield_path="$(pwd)/2-car.so"
    export runs=2500
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."

    export blueprint_path="$(pwd)/3-Car Declared Action_blueprint.xml"
    export shield_path="$(pwd)/2-car.so"
    export runs=5000
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export blueprint_path="$(pwd)/3-Car Declared Action_blueprint.xml"
    export shield_path="$(pwd)/2-car.so"
    export runs=10000
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export blueprint_path="$(pwd)/3-Car Declared Action_blueprint.xml"
    export shield_path="$(pwd)/2-car.so"
    export runs=20000
    export checks=1000
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
done