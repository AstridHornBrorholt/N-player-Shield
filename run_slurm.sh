EXECUTOR="sbatch --out="~/output_latest_run.txt" --exclude=rome0[1-3],dhabi0[1-3],naples0[1-3],vmware0[1-4] --partition=cpu -n1 --mem=16G "

export runs=1000
export checks=1000
export max_cars=6
$EXECUTOR "./run_single.sh"

export runs=2000
export checks=1000
export max_cars=6
$EXECUTOR "./run_single.sh"

export runs=4000
export checks=1000
export max_cars=6
$EXECUTOR "./run_single.sh"

export runs=8000
export checks=1000
export max_cars=6
$EXECUTOR "./run_single.sh"