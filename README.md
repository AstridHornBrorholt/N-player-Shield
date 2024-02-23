# N-player Shield

## How to Run

First time an experiment is run, make sure that the correct folder structure is in place. There should be a file path at `~/Results/N-player ##` where `##` matches the folder name containing the experiments. This is to support logging of slurm jobs. OBS: The cause of the error will not be printed because slurm is annoying.

Start an experiment by navigating to its sub-folder in this project. If it is run from any other working directory, it will fail. These experiments are made to run as parallel slurm jobs where possible. As a rule, the file `run_slurm.sh` starts multiple jobs by queueing instances of `run_single.sh` with different bash variables exported. This calls `Run Experiment.jl` with a bunch of command line arguments. Calling `run_single.sh` on its own is likely to result in failure because of undeclared variables. Use `run_single_cli.sh` instead. Note that the arguments to different versions of this script may vary. (Check them by reading the script.)

## Index of Experiments

| Folder Prefix  |  |
|--|--|
|CC| Cruise Control Example|
|CP| Chemical Production Example|

The names of these experiments don't really match what we call it in the article. We always come up with new names for things in the writing process, so I've chosen to keep the experiment names for now. Changing the folder names is time-consuming and error-prone anyway.

Training budget is handled inconsistently. In some copies of `Run Experiment.jl` the number of `runs` specified will be multiplied by the number of agents. I think in at least one case the multiplication has to be done manually. 

| Folder Suffix | Term Used in Paper | |
|---------------|--------------------|-|
| \<none\>      | Distributed Shield & Cascading Learning | Shielding: Individual shield for each agent. Learning: Train one unit, make the unit's strategy part of the environment. Then train the next unit etc.  |
| Non-specialized | Distributed Shield & Distributed Learning | Shielding: See previous. Learning: Spend entire training budget on training the first unit, then apply the learned policy to all agents. |
| Centralized Control | Distributed Shield & Centralized Learning | Shielding: y'know. Learning: Spend entire training budget on one single policy that controls all agents. |
| Centralied Shield | Centralized Shield & Centralized Learning | CC Only. A shield spanning 3 cars (1 uncontrollable, 2 controllable) is compared to a shield spanning 2 cars (1 uncontrollable 1 controllable). Doing distributed or cascading learning with a centralized shield doesn't really make sense, so only centralized learning is done. |