echo "Scheduling slurm jobs"

export log_output="$HOME/Results/N-player CC/log.txt"

date > "$log_output"
ARGS="--out=/dev/null --exclude=rome0[1-3],dhabi0[1-3],naples0[1-3],vmware0[1-4] --partition=cpu -n1 --mem=16G "

export runs=10000
export checks=1000
export max_cars=6
sbatch $ARGS ./run_single.sh
echo "Job scheduled."

export runs=20000
export checks=1000
export max_cars=6
sbatch $ARGS ./run_single.sh
echo "Job scheduled."

export runs=40000
export checks=1000
export max_cars=6
sbatch $ARGS ./run_single.sh
echo "Job scheduled."

export runs=80000
export checks=1000
export max_cars=6
sbatch $ARGS ./run_single.sh
echo "Job scheduled."