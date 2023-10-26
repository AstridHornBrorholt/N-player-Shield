#!/bin/bash
echo "Scheduling slurm jobs"

export log_output="$HOME/Results/N-player CC/log.txt"

date >> "$log_output"
ARGS="--out=/dev/null --exclude=rome0[1-3],dhabi0[1-3],naples0[1-3],vmware0[1-4] --partition=cpu -n1 --mem=4G --job-name StdCC"

repetitions=10

for ((r=1; r<=$repetitions; r++))
do
    export repetition=$r
    

    export blueprint_path="$(pwd)/3-Car Centralized_blueprint.xml"
    export runs=250
    export checks=100
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."

    export blueprint_path="$(pwd)/3-Car Centralized_blueprint.xml"
    export runs=500
    export checks=100
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export blueprint_path="$(pwd)/3-Car Centralized_blueprint.xml"
    export runs=100
    export checks=100
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export blueprint_path="$(pwd)/3-Car Centralized_blueprint.xml"
    export runs=200
    export checks=100
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."

    export blueprint_path="$(pwd)/3-Car_blueprint.xml"
    export runs=250
    export checks=100
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."

    export blueprint_path="$(pwd)/3-Car_blueprint.xml"
    export runs=500
    export checks=100
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export blueprint_path="$(pwd)/3-Car_blueprint.xml"
    export runs=100
    export checks=100
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
    
    export blueprint_path="$(pwd)/3-Car_blueprint.xml"
    export runs=200
    export checks=100
    sbatch $ARGS ./run_single.sh
    echo "Job scheduled."
done