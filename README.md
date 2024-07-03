# N-player Shield

## How to Run

First time an experiment is run, make sure that the correct folder structure is in place. There should be a file path at `~/Results/N-player ##` where `##` matches the folder name containing the experiments. This is to support logging of slurm jobs. OBS: The cause of the error will not be printed because slurm is annoying.

Start an experiment by navigating to its sub-folder in this project. If it is run from any other working directory, it will fail. These experiments are made to run as parallel slurm jobs where possible. As a rule, the file `run_slurm.sh` starts multiple jobs by queueing instances of `run_single.sh` with different bash variables exported. This calls `Run Experiment.jl` with a bunch of command line arguments. Calling `run_single.sh` on its own is likely to result in failure because of undeclared variables. Use `run_single_cli.sh` instead. Note that the arguments to different versions of this script may vary. (Check them by reading the script.)

## Index of Experiments

| Folder Prefix  |  |
|--|----------------------------|
|CC| Cruise Control Example     |
|CP| Chemical Production Example|

The names of these experiments don't really match what we call it in the article. We always come up with new names for things in the writing process, so I've chosen to keep the experiment names for now. Changing the folder names is error-prone.

Main experiments: 

| Folder Suffix | Term Used in Paper | |
|---------------|--------------------|-|
| \<none\>      | Distributed Shield & Cascading Learning | Shielding: Individual shield for each agent. Learning: Train one unit, make the unit's strategy part of the environment. Then train the next unit etc.  |
| Non-specialized | Distributed Shield & Distributed Learning | Shielding: See previous. Learning: Spend entire training budget on training the first unit, then apply the learned policy to all agents. |
| Centralized Control | Distributed Shield & Centralized Learning | Shielding: y'know. Learning: Spend entire training budget on one single policy that controls all agents. |
| Centralied Shield | Centralized Shield & Centralized Learning, Distributed Shield & Centralized Learning, Co-ordinated Shield & Centralized Learning | CC Only. Shields with limited range of 50m compared to 200m default. Doing distributed or cascading learning with a centralized shield doesn't really make sense, so only centralized learning is done. |

Other:

| Folder | Term Used in Paper | |
|---------------|--------------------|-|
| CC Shield|  | Contains code for generating the distributed and co-ordinated shields, as well as the generated shield files. |
| CC Shield Transfer |  | An experiment where the CC shield was applied to a variant of CC with different mechanics, through a transformation function. Turns out this is only possible for very specific combinations of mechanics. |
| Strategies |  | Some strategies that have been exported and that the non-blueprint UPPAAL models use. |
| Exported Figures |  | Y'know. |