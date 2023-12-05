#!/bin/bash
export runs=${1}
export checks=${2}
export max_cars=${3}
export repetition=1


for ((f=2; f<=$max_cars; f++))
do
    export fleet_size=$f
    ./run_single.sh
done