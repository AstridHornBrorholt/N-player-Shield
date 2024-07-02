## Preface ##
using Dates
# The fruit is there to distinguish different runs writing to the same output concurrently. This doesn't seem to be a problem after all but I enjoy the splash of colour.
emoji = ["🍇", "🍈", "🍉", "🍊", "🍋", "🍌", "🍍", "🥭", "🍎", "🍏", "🍐", "🍑", "🍒", "🍓", "🫐", "🥝", "🍅", "🫒", "🥥"]
🍎🍐 = join(rand(emoji, 2), "")
node = get(ENV, "SLURMD_NODENAME", "local")
function status(str) 
    time = Dates.format(Dates.now(), "dd/mm HH:MM")
    println("$time $node $🍎🍐 $str")
    flush(stdout)
end
using Pkg
Pkg.activate("..")

using ArgParse
include("Create Fleet.jl")

## Args and Constants ##
⨝ = joinpath
← = push!

begin
	s = ArgParseSettings()
	@add_arg_table s begin
	     "--runs"
			arg_type=Int
			required=true
            help="Total number of training episodes spent. This number is divied out to each car in the cascading training."
		"--checks"
			arg_type=Int
			required=true
        "--max-cars"
            arg_type=Int
            required=true
        "--repetition"
            arg_type=Int
            required=true
		"--results-dir"
			default=homedir() ⨝ "Results/N-player CC"
        "--verifyta-path"
            default=homedir() ⨝ "opt/uppaal-5.0.0-linux64/bin/verifyta.sh"
        "--blueprint-path"  
            default=pwd() ⨝ "Fleet_blueprint.xml"
        "--shield-path"  
            default=pwd() ⨝ "../CC Shield/libshield.so"
        "--skip-training"
            action=:store_true
            help="Try to load existing strategies from results directory."
	end
end;

args = parse_args(s)

runs = args["runs"]
checks = args["checks"]
max_cars = args["max-cars"]
repetition = args["repetition"]
results_dir = args["results-dir"]
verifyta_path = args["verifyta-path"]
skip_training = args["skip-training"]
status("Starting... $((;runs, max_cars, repetition, skip_training))")

isdir(results_dir) || mkdir(results_dir) # Error if path is invalid except if it is only the last folder missing.
isfile(verifyta_path) || error("File verifyta not found at path $verifyta_path")

cars_to_train = max_cars - 1
runs_per_car = round(Int64, runs/cars_to_train)

verifyta_args = "-s --epsilon 0.001 --max-iterations 1 --good-runs $runs_per_car --total-runs $runs_per_car --runs-pr-state $runs_per_car"

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

## Mainmatter ##
try
    strategy_paths = String[]
    for N in 2:max_cars
        status("Running Fleet of $N Cars...  (repetition=$repetition)")
        outfile = query_results_dir ⨝ "Fleet of $N Cars.txt"
        model_path, queries_path = create_fleet(blueprint_path, strategy_paths, shield_path, models_dir; checks, skip_training)
        strategy_paths ← (working_dir ⨝ "Models/car$(N - 1).json")
        open(outfile, "w") do io
            result = [verifyta_call..., model_path, queries_path] |> Cmd |> read |> String
            write(io, result)
        end
        status("Done running Fleet of $N Cars.  (repetition=$repetition)")
    end

    status("All done.")
catch e
    throw(ExceptionWithNodeID(e, node))
end