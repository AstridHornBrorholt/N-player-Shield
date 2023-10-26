# N-player Shield

## Expeirmental setups

There is not a seperate file to run each type of experiments. This is on the todos, but such are a lot of things. 

Instead, the different experiments are conducted by editing the code files in various ways, as detailed here.

### Distributed Controller + Distributed Shield

This should be the standard setup. I'm counting hard on this configuration being the last thing I pushed. Start with `run_slurm.sh` or `run_single_cli.sh`.

### Centralized Controller + Distributed Shield

This one actually does have a seperate folder. It is copy-pasta of the root folder. Start with `Centralized Controller/run_slurm.sh` or `Centralized Controller/run_single_cli.sh`.

### Non-specialized Distributed Controller + Distributed Shield

Non-specialized meaning that the controller of the first car is simply repeated to the following cars. 

Check that `Run Experiment.jl` interprets the `--skip-training` flag as copying the `car1.json` strategy as the controller throughout the fleet. There should be a "misnomer" warning in the description of the flag if this is the case. Of course, this requires the `car1.json` strategy to be present in the results folder for the specified number of runs already.

### Centralized Shield

Still a work in progress at the time of writing. It also has its own folder. For now I am going to say that a centralized shield will also necessitate a centralized controller.