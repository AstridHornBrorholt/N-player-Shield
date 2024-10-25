# N-player Shield

## Installing Dependencies

It should be possible to run this code on many popular operating systems, but it has been developed on tested on Ubuntu 24.04.1 LTS. The following instructions are specific to this OS, but all dependencies are available for a wide range of systems.

UPPAAL and Julia are required to run the main experiments, while Python is a requirement for running the benchmarks in the BenchMARL sub-module.

### Install Julia 1.10.4 and Download Packages

	cd ~/Downloads
	wget https://julialang-s3.julialang.org/bin/linux/x64/1.10/julia-1.10.4-linux-x86_64.tar.gz
	tar zxvf julia-1.10.4-linux-x86_64.tar.gz
	mv julia-1.10.4/ ~/julia-1.10.4
	sudo ln -s ~/julia-1.10.4/bin/julia /usr/local/bin/julia

Download required julia packages for this repository. Note that the `]` key activates the package manager interface. Once done, press backspace to exit the package manager, and type `exit()` to quit the REPL.

	cd <</path/to/this/repository>>
	julia --project=.
	] instantiate

### Install UPPAAL 5.0, and Activate License

Install the full Java runtime environment.

    sudo apt install default-jre

Download the application. If the following `wget` request is denied, please visit uppaal.org and follow download instructions.

	mkdir ~/opt
	cd ~/opt
	wget https://download.uppaal.org/uppaal-5.0/uppaal-5.0.0/uppaal-5.0.0-linux64.zip
	unzip uppaal-5.0.0-linux64.zip

Note that the code depends on the exact installation location of `~/opt/uppaal-5.0.0-linux64`.

Retrieve a license from https://uppaal.veriaal.dk/academic.html or visit uppaal.org for more info. Once you have your license, activate it by running

	~/opt/uppaal-5.0.0-linux64/bin/verifyta.sh --key <<YOUR-LICENSE-KEY>>

### Set up Slurm (optional)

Slurm is used to run multiple experiments at once, either on a cluster, or on multiple threads on your local machines. 
Follow this guide to install slurm on your local machine: https://ubuntuforums.org/showthread.php?t=2404746 (not tested)

**Alternatives:**

- Use the `run_single_cli.sh` scripts to manually start individual parts of an experiment.
- Replace all `sbatch $ARGS ./run_single.sh` statements in the `run_slurm.sh` scripts with just `./run_single.sh` to run the experiment sequentially.

### Install Python 3.12

    sudo apt update
    sudo apt install python3.12

### Create a Virtual Environment and Install Packages

Sicne the packages include a `pip install -e` (which is hard to uninstall/overwrite or so I'm told), it is not recommended to add this to your global package-soup. I think there are conda options also.

	cd <</path/to/this/repository>>/BenchMARL
    python3.12 -m venv venv
    source venv/bin/activate
    cd ..
    pip install -r requirements.txt

If `requirements.txt` gives you trouble, try

    pip install -e BenchMARL
    pip install matplotlib numpy

(Yes, I realize that numpy is a bit superflouous when there are perfectly good tensors right there already. I needed it for some copy-pasted code that was not easily translated.)

### Install CUDA (optional)

I'll be honest, I tried to do this, but couldn't follow the guide. 

Official guide: https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#ubuntu

**Alternative:** Change it to run on cpu, by replacing the `'cuda'` strings in `BenchMARL/run_single.sh` with `'cpu'`.
This wil make it slower to run, but not prohibitively so.

## How to Run

### Main Experiments

Start an experiment by navigating to its sub-folder in this project. If it is run from any other working directory, it will fail. 

These experiments are made to run as parallel slurm jobs where possible. As a rule, the file `run_slurm.sh` starts multiple jobs by queueing instances of `run_single.sh` with different bash variables exported. This calls `Run Experiment.jl` with a bunch of command line arguments. 

Calling `run_single.sh` on its own results in errors from undeclared variables. Use `run_single_cli.sh` instead. Note that the arguments to this script may vary depending on the experiment. (Check them by reading the script.)

## Index of Experiments

### Main Experiments

Experiment names consist of a prefix and a suffix.
These names do not match the terms used in the paper, so tables are given here to give a translation.

| Folder Prefix  | Experiment   |
|--|----------------------------|
|CC| Cruise Control (Car Platoon) Example     |
|CP| Chemical Production Example|

The names of these experiments don't really match what we call it in the article. We always come up with new names for things in the writing process, so I've chosen to keep the experiment names for now. Changing the folder names is error-prone.

| Folder Suffix | Term Used in Paper | Explanation |
|---------------|--------------------|-------------|
| \<none\>      | Distributed Shield & Cascading Learning | Shielding: Individual shield for each agent. Learning: Train one unit, make the unit's strategy part of the environment. Then train the next unit etc.  |
| Centralized Control | Distributed Shield & Centralized Learning | Shielding: y'know. Learning: Spend entire training budget on one single policy that controls all agents. |
| Centralied Shield | Centralized Shield | Code for generating a centralized shield, as well as experiments which were not included in the paper. See readme in subfolder. CC Only. |
| Non-specialized | (not present in paper) | Shielding: See previous. Learning: Spend entire training budget on training the first unit, then apply the learned policy to all agents. |

#### Additional folders

| Folder | Contents |
|--------|-|
| CC Shield | Contains code for generating the distributed and co-ordinated shields, as well as the generated shield files. |
| CC Shield Transfer | An experiment where the CC shield was applied to a variant of CC with different mechanics, through a transformation function. Turns out this is only possible for very specific combinations of mechanics. |
| Strategies | Some strategies that have been exported and that the non-blueprint UPPAAL models use. |
| Exported Figures | Y'know. |


### Benchmark

The MAPPO benchmark is given in the modified BenchMARL repository, which is included as a git sub-module in this repository. Custom environments for the *car platoon* and *chemical production plant* case studiens have been created.
