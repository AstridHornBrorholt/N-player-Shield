echo "Scheduling slurm jobs"

export log_output="$HOME/Results/N-player CC/log.txt"

date >> "$log_output"
ARGS="--out=/dev/null --exclude=rome0[1-3],dhabi0[1-3],naples0[1-3],vmware0[1-4] --partition=cpu -n1 --mem=16G "

export max_cars=6
export repetitions=3

export runs=100
export checks=10
sbatch $ARGS ./run_single.sh
echo "Job scheduled."

export runs=200
export checks=10
sbatch $ARGS ./run_single.sh
echo "Job scheduled."

export runs=400
export checks=10
sbatch $ARGS ./run_single.sh
echo "Job scheduled."

export runs=800
export checks=10
sbatch $ARGS ./run_single.sh
echo "Job scheduled."