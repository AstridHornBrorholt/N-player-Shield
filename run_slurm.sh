echo "Scheduling slurm jobs"

export log_output="$HOME/Results/N-player CC/log.txt"

date > "$log_output"
OUT="-o=$log_output"
ARGS="--exclude=rome0[1-3],dhabi0[1-3],naples0[1-3],vmware0[1-4] --partition=cpu -n1 --mem=16G "

export runs=1000
export checks=1000
export max_cars=6
sbatch "$OUT" $ARGS ./run_single.sh
echo "Job scheduled."

export runs=2000
export checks=1000
export max_cars=6
sbatch "$OUT" $ARGS ./run_single.sh
echo "Job scheduled."

export runs=4000
export checks=1000
export max_cars=6
sbatch "$OUT" $ARGS ./run_single.sh
echo "Job scheduled."

export runs=8000
export checks=1000
export max_cars=6
sbatch "$OUT" $ARGS ./run_single.sh
echo "Job scheduled."