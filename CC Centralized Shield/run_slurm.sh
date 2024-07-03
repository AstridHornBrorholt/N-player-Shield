#!/bin/bash
echo "Scheduling slurm jobs"

export log_output="$HOME/Results/N-player CC/log.txt"

date >> "$log_output"
ARGS="--out=/dev/null --partition=rome -n1 --mem=4G --job-name 'CCCentralizedShield'"

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