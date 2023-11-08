#!/bin/bash
export runs=${1}
export checks=${2}
export repetition=1

# Not really a "single" run anymore. But yea run both versions. In slurm this can be separate jobs.
export blueprint_path="$(pwd)/3-Car_blueprint.xml"
export shield_path="$(pwd)/2-car.so"
./run_single.sh
export blueprint_path="$(pwd)/3-Car Centralized_blueprint.xml"
export shield_path="$(pwd)/3-car.so"
./run_single.sh