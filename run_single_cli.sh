#!/bin/bash
export runs=${1:-100}
export checks=${2:-100}
export max_cars=${3:-4}
export repetitions=${4:-2}
./run_single.sh