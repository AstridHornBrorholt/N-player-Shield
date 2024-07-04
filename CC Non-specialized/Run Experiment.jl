## Preface ##
using Dates
# The fruit is there to distinguish different runs writing to the same output concurrently. This doesn't seem to be a problem after all but I enjoy the splash of colour.
emoji = ["🔴", "🟠", "🟡", "🟢", "🔵", "🟣", "🟤", "⚫", "⚪"]
🔴🟢 = join(rand(emoji, 2), "")
node = get(ENV, "SLURMD_NODENAME", "local")
function status(str) 
    time = Dates.format(Dates.now(), "dd/mm HH:MM")
    println("$time $node $🔴🟢 $str")
    flush(stdout)
end
using Pkg
Pkg.activate("..", io=devnull)

using ArgParse
include("../CC/Create Fleet.jl")

## Args and Constants ##
⨝ = joinpath
← = push!

begin
	s = ArgParseSettings()
	@add_arg_table s begin
	     "--runs"
			arg_type=Int
			required=true
            help="Total number of training runs. Since only one agent is trained, it gets the whole budget."
		"--checks"
			arg_type=Int
			required=true
        "--fleet-size"
            arg_type=Int
            required=true
        "--repetition"
            arg_type=Int
            required=true
		"--results-dir"
			default=homedir() ⨝ "Results/N-player CC Non-specialized"
        "--verifyta-path"
            default=homedir() ⨝ "opt/uppaal-5.0.0-linux64/bin/verifyta.sh"
        "--blueprint-path"  
            default=pwd() ⨝ "../CC/Fleet_blueprint.xml"
        "--shield-path"  
            default=pwd() ⨝ "../CC Shield/libshield.so"
        "--skip-training"
            action=:store_true
            help="MISNOMER: Use car1.json for all cars in the fleets (must exist) without training any strategies."
	end
end;

args = parse_args(s)

runs = args["runs"]
checks = args["checks"]
fleet_size = args["fleet-size"]
repetition = args["repetition"]
results_dir = args["results-dir"]
verifyta_path = args["verifyta-path"]
skip_training = args["skip-training"]
status("Starting... $((;runs, checks, fleet_size, repetition))")

isdir(results_dir) || mkdir(results_dir) # Error if path is invalid except if it is only the last folder missing.
isfile(verifyta_path) || error("File verifyta not found at path $verifyta_path")

verifyta_args = "-s --epsilon 0.001 --max-iterations 1 --good-runs $runs --total-runs $runs --runs-pr-state $runs"

verifyta_call = String[
    verifyta_path,
    split(verifyta_args, " ")...
]

blueprint_path = args["blueprint-path"]
shield_path = args["shield-path"]

## Resolving Paths ##
isfile(shield_path) || error("Shield file not found at $shield_path")

shield_path′ = results_dir ⨝ basename(shield_path)
cp(shield_path, shield_path′, force=true)
shield_path = shield_path′

working_dir = results_dir ⨝ "$runs Runs" ⨝ "Repetition $repetition"
mkpath(working_dir)
query_results_dir = working_dir ⨝ "Query Results"
mkpath(query_results_dir)
models_dir = working_dir ⨝ "Models"
mkpath(models_dir)

struct ExceptionWithNodeID <: Exception
    captured_exception
    node_id
end

# Run a fleet with one learner car and one random car in front,
#plus as many cars in betweeen, as there are strategies provided in `strategy_paths`
function do_run(strategy_paths; skip_training)
    N = length(strategy_paths) + 2
    status("Running Fleet of $N Cars...  (repetition=$repetition)")
    outfile = query_results_dir ⨝ "Fleet of $N Cars.txt"
    model_path, queries_path = create_fleet(blueprint_path, strategy_paths, shield_path, models_dir; checks, skip_training)
    open(outfile, "w") do io
        result = [verifyta_call..., model_path, queries_path] |> Cmd |> read |> String
        write(io, result)
    end
    status("Done running Fleet of $N Cars.  (repetition=$repetition)")
end

## Mainmatter ##
try
    # Train a distributed strategy on the first car
    do_run([], skip_training=false)

    # Use this strategy for the next (fleet_size - 1) cars.
    strategy_path = (models_dir ⨝ "car1.json")
    strategy_paths = [strategy_path for _ in 2:fleet_size - 1]
    
    # Hack: When skip_training==true, the function will look for a strategy with the appropriate number.
    # This is a quick way to ensure that the last car in the fleet also uses the strategy of car1.
    cp(strategy_path, models_dir ⨝ "car$(fleet_size - 1).json")

    # Do the actual run
    do_run(strategy_paths, skip_training=true)

    status("All done.")
catch e
    throw(ExceptionWithNodeID(e, node))
end